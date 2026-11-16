<?php

namespace App\Http\Controllers\Api\Appointment;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\Appointment\CancelAppointmentRequest;
use App\Http\Requests\Api\Appointment\RescheduleAppointmentRequest;
use App\Http\Requests\Api\Appointment\StoreAppointmentRequest;
use App\Http\Resources\AppointmentResource;
use App\Jobs\SendAppointmentReminderJob;
use App\Models\Appointment;
use App\Models\ProfessionalProfile;
use App\Models\User;
use App\Services\SlotService;
use App\Services\WalletService;
use Carbon\CarbonImmutable;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class AppointmentController extends Controller
{
    public function __construct(
        private SlotService $slots,
        private WalletService $wallet,
    ) {}

    /**
     * GET /api/appointments
     * Role-aware: clients see their own bookings; pros see theirs.
     */
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        $q = Appointment::query()
            ->with(['client', 'professional'])
            ->orderByDesc('scheduled_at');

        $q->where(function ($qq) use ($user) {
            $qq->where('user_id', $user->id)
               ->orWhere('professional_user_id', $user->id);
        });

        if ($status = $request->query('status')) {
            $q->where('status', $status);
        }
        if ($from = $request->query('from')) {
            $q->where('scheduled_at', '>=', CarbonImmutable::parse($from));
        }
        if ($to = $request->query('to')) {
            $q->where('scheduled_at', '<=', CarbonImmutable::parse($to));
        }

        $page = $q->paginate((int) $request->query('per_page', 20));
        return response()->json([
            'data' => AppointmentResource::collection($page->items())->resolve($request),
            'meta' => [
                'current_page' => $page->currentPage(),
                'last_page'    => $page->lastPage(),
                'per_page'     => $page->perPage(),
                'total'        => $page->total(),
            ],
        ]);
    }

    /**
     * GET /api/appointments/{id}
     * Either party (client, pro, or admin) can view; everyone else 403.
     */
    public function show(Request $request, int $id): JsonResponse
    {
        $appt = Appointment::with(['client', 'professional', 'callSession', 'review'])->findOrFail($id);
        $this->authorizeAccess($request->user(), $appt);
        return response()->json((new AppointmentResource($appt))->toArray($request));
    }


    /**
     * POST /api/appointments
     * Race-safety: DB::transaction + SlotService check + unique index
     * (`appointments_user_id_scheduled_at_unique` on the user side, set
     * up in Task 1's migration) provides a hard backstop. The professional
     * side is checked in code (and in Task 6 the admin reporting surfaces
     * any rare double-book leaks).
     */
    public function store(StoreAppointmentRequest $request): JsonResponse
    {
        $client   = $request->user();
        $proId    = (int) $request->input('professional_user_id');
        $tz       = $request->input('user_timezone') ?: $client->timezone ?: 'UTC';
        $duration = (int) ($request->input('duration_minutes')
            ?: optional($client->professionalProfile)->session_duration_minutes
            ?: 45);

        $professional = User::where('role', 'professional')->findOrFail($proId);
        $profile      = $professional->professionalProfile;
        abort_unless($profile, 422, 'Professional has no profile.');
        abort_unless($profile->verification_status === 'approved', 422, 'Professional is not verified.');
        abort_unless($profile->is_accepting_clients, 422, 'Professional is not accepting clients.');

        // Slots are issued as UTC ISO (`start_at`). Preserve the instant.
        $startUtc = CarbonImmutable::parse($request->input('scheduled_at'))->utc();
        if ($startUtc->isPast()) {
            throw ValidationException::withMessages(['scheduled_at' => ['Cannot book in the past.']]);
        }

        $priceCents = $profile->hourly_rate_cents;
        $currency   = $profile->currency;
        $sessionType = $request->input('session_type', 'video');

        if ($priceCents > 0) {
            $wallet = $this->wallet->walletFor($client, $currency);
            if ($wallet->balance_cents < $priceCents) {
                return response()->json([
                    'message'        => 'Insufficient wallet balance',
                    'required_cents' => $priceCents,
                    'balance_cents'  => $wallet->balance_cents,
                    'currency'       => $currency,
                ], 402);
            }
        }

        return DB::transaction(function () use (
            $request, $client, $professional, $profile, $startUtc, $duration, $tz, $priceCents, $currency, $sessionType
        ) {
            // Re-check inside the transaction.
            if (! $this->slots->isSlotBookable($professional, $startUtc, $duration)) {
                throw ValidationException::withMessages(['scheduled_at' => ['Slot is no longer available.']]);
            }
            // Race-safety: also check the user-side unique-index candidate.
            $userCollision = Appointment::where('user_id', $client->id)
                ->whereIn('status', ['pending', 'confirmed', 'in_progress'])
                ->where('scheduled_at', $startUtc)
                ->exists();
            if ($userCollision) {
                throw ValidationException::withMessages(['scheduled_at' => ['You already have a session at this time.']]);
            }

            // Auto-confirm so client and pro can both join without a separate accept step.
            $appt = Appointment::create([
                'user_id'                  => $client->id,
                'professional_user_id'     => $professional->id,
                'professional_profile_id'  => $profile->id,
                'scheduled_at'             => $startUtc,
                'duration_minutes'         => $duration,
                'session_type'             => $sessionType,
                'status'                   => 'confirmed',
                'confirmed_at'             => now(),
                'price_cents'              => $priceCents,
                'currency'                 => $currency,
                'user_timezone'            => $tz,
                'professional_timezone'    => $professional->availabilitySlotRules()->first()?->timezone ?: 'UTC',
            ]);

            if ($priceCents > 0) {
                $this->wallet->debit($client, $priceCents, $currency, 'payment', $appt);
            }

            // Schedule reminders. Task 4 wires the actual notification channels.
            SendAppointmentReminderJob::dispatch($appt->id, 'reminder_24h')
                ->delay($startUtc->subHours(24));
            SendAppointmentReminderJob::dispatch($appt->id, 'reminder_1h')
                ->delay($startUtc->subHour());

            return response()->json((new AppointmentResource($appt->fresh()))->toArray($request), 201);
        });
    }

    /**
     * PUT /api/appointments/{id}/reschedule
     */
    public function reschedule(RescheduleAppointmentRequest $request, int $id): JsonResponse
    {
        $appt = Appointment::findOrFail($id);
        $this->authorizeAccess($request->user(), $appt, requireClient: true);
        abort_unless(in_array($appt->status, ['pending','confirmed']), 422, 'Cannot reschedule in current status.');

        $tz       = $request->input('user_timezone') ?: $appt->user_timezone ?: 'UTC';
        $newStart = CarbonImmutable::parse($request->input('scheduled_at'))->setTimezone($tz)->setTimezone('UTC');
        $duration = $appt->duration_minutes;

        if ($newStart->isPast()) {
            throw ValidationException::withMessages(['scheduled_at' => ['Cannot reschedule to the past.']]);
        }

        DB::transaction(function () use ($appt, $newStart, $duration) {
            if (! $this->slots->isSlotBookable($appt->professional, $newStart, $duration)) {
                throw ValidationException::withMessages(['scheduled_at' => ['New slot is not available.']]);
            }
            $appt->update(['scheduled_at' => $newStart, 'status' => 'rescheduled']);
            // re-arm reminders
            SendAppointmentReminderJob::dispatch($appt->id, 'reminder_24h')->delay($newStart->subHours(24));
            SendAppointmentReminderJob::dispatch($appt->id, 'reminder_1h')->delay($newStart->subHour());
        });

        return response()->json((new AppointmentResource($appt->fresh()))->toArray($request));
    }

    /**
     * PUT /api/appointments/{id}/cancel
     * Cancellation policy: free up to 24h before; 50% charge 24-2h before;
     * non-refundable < 2h before. Task 9 wires the actual refund flow.
     */
    public function cancel(CancelAppointmentRequest $request, int $id): JsonResponse
    {
        $appt = Appointment::findOrFail($id);
        $this->authorizeAccess($request->user(), $appt);
        abort_unless(in_array($appt->status, ['pending','confirmed']), 422, 'Cannot cancel in current status.');

        $hoursUntil = $appt->scheduled_at
            ? now()->diffInHours($appt->scheduled_at)
            : 0;
        $policy = match (true) {
            $hoursUntil >= 24 => 'full_refund',
            $hoursUntil >=  2 => 'partial_refund_50',
            default          => 'no_refund',
        };

        DB::transaction(function () use ($appt, $request, $policy) {
            $appt->update([
                'status'              => 'cancelled',
                'cancelled_at'        => now(),
                'cancelled_by'        => $request->user()->id,
                'cancellation_reason' => $request->input('reason') ?: $policy,
            ]);
        });

        return response()->json([
            'message'            => 'Appointment cancelled.',
            'refund_policy'      => $policy,
            'appointment'        => (new AppointmentResource($appt->fresh()))->resolve($request),
        ]);
    }

    private function authorizeAccess(User $user, Appointment $appt, bool $requireClient = false): void
    {
        $isParty = $user->id === $appt->user_id || $user->id === $appt->professional_user_id;
        $isAdmin = method_exists($user, 'hasAnyRole') && $user->hasAnyRole(['admin', 'support']);
        abort_unless($isParty || $isAdmin, 403, 'Not your appointment.');

        if ($requireClient && $user->id !== $appt->user_id) {
            abort(403, 'Only the client can perform this action.');
        }
    }
}