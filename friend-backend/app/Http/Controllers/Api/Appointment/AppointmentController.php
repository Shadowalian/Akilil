<?php

namespace App\Http\Controllers\Api\Appointment;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\Appointment\CancelAppointmentRequest;
use App\Http\Requests\Api\Appointment\RescheduleAppointmentRequest;
use App\Http\Requests\Api\Appointment\StoreAppointmentRequest;
use App\Http\Resources\AppointmentResource;
use App\Jobs\SendAppointmentReminderJob;
use App\Models\Appointment;
use App\Models\AppointmentParticipant;
use App\Models\Dependent;
use App\Models\ProfessionalProfile;
use App\Models\User;
use App\Notifications\SessionInviteNotification;
use App\Services\CookingRules;
use App\Services\EarningsService;
use App\Services\SlotService;
use App\Services\WalletService;
use App\Support\AgeGate;
use Illuminate\Support\Facades\Notification;
use Illuminate\Support\Str;
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
        private CookingRules $cooking,
        private EarningsService $earnings,
    ) {}

    private const WITH = ['client', 'professional', 'dependent', 'recipe', 'participants'];

    /**
     * GET /api/appointments
     * Role-aware: clients see their own bookings; pros see theirs.
     */
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        $q = Appointment::query()
            ->with(self::WITH)
            ->visibleTo($user)
            ->orderByDesc('scheduled_at');

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
        $appt = Appointment::with([...self::WITH, 'callSession', 'review'])->findOrFail($id);
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
        $client = $request->user();
        // The account holder consents and pays, so they must be an adult.
        AgeGate::requireAdultPayer($client);

        $proId = (int) $request->input('professional_user_id');
        $tz    = $request->input('user_timezone') ?: $client->timezone ?: 'UTC';

        $professional = User::where('role', 'professional')->findOrFail($proId);
        $profile      = $professional->professionalProfile()->with('category')->first();
        abort_unless($profile, 422, 'Professional has no profile.');
        abort_unless($profile->verification_status === 'approved', 422, 'Professional is not verified.');
        abort_unless($profile->is_accepting_clients, 422, 'Professional is not accepting clients.');
        abort_if($professional->id === $client->id, 422, 'You cannot book yourself.');

        $duration = (int) ($request->input('duration_minutes') ?: $profile->session_duration_minutes ?: 45);

        // Slots are issued as UTC ISO (`start_at`). Preserve the instant.
        $startUtc = CarbonImmutable::parse($request->input('scheduled_at'))->utc();
        if ($startUtc->isPast()) {
            throw ValidationException::withMessages(['scheduled_at' => ['Cannot book in the past.']]);
        }

        [$format, $dependent, $participants] = $this->resolveCare($request, $client, $profile);

        // Chefs: a recipe is part of the booking, and there must be time to shop.
        $recipe = null;
        if ($profile->isCookingPillar()) {
            $recipe = $this->cooking->requireRecipe($professional, $request->input('recipe_id'));
            $this->cooking->requireLeadTime($startUtc);
        }

        $priceCents  = $profile->priceFor($format);
        $currency    = $profile->currency;
        $sessionType = $request->input('session_type', 'video');

        if ($priceCents > 0 && ! $this->wallet->canAfford($client, $priceCents, $currency)) {
            return response()->json([
                'message'        => 'Insufficient wallet balance',
                'required_cents' => $priceCents,
                'balance_cents'  => $this->wallet->walletFor($client, $currency)->balance_cents,
                'currency'       => $currency,
            ], 402);
        }

        $appt = DB::transaction(function () use (
            $request, $client, $professional, $profile, $startUtc, $duration, $tz,
            $priceCents, $currency, $sessionType, $format, $dependent, $participants, $recipe
        ) {
            // Serialise bookings against this professional so two clients
            // can't both pass the slot check for the same time.
            User::whereKey($professional->id)->lockForUpdate()->first();

            if (! $this->slots->isSlotBookable($professional, $startUtc, $duration)) {
                throw ValidationException::withMessages(['scheduled_at' => ['Slot is no longer available.']]);
            }
            $userCollision = Appointment::where('user_id', $client->id)
                ->whereIn('status', ['pending', 'confirmed', 'in_progress'])
                ->where('scheduled_at', $startUtc)
                ->exists();
            if ($userCollision) {
                throw ValidationException::withMessages(['scheduled_at' => ['You already have a session at this time.']]);
            }

            // Paid up front, so it is confirmed for both sides immediately.
            $appt = Appointment::create([
                'user_id'                  => $client->id,
                'dependent_id'             => $dependent?->id,
                'professional_user_id'     => $professional->id,
                'professional_profile_id'  => $profile->id,
                'recipe_id'                => $recipe?->id,
                'scheduled_at'             => $startUtc,
                'duration_minutes'         => $duration,
                'session_type'             => $sessionType,
                'care_format'              => $format,
                'status'                   => 'confirmed',
                'confirmed_at'             => now(),
                'price_cents'              => $priceCents,
                'currency'                 => $currency,
                'user_timezone'            => $tz,
                'professional_timezone'    => $professional->availabilitySlotRules()->first()?->timezone ?: 'UTC',
                'client_note'              => $request->input('client_note'),
            ]);

            foreach ($participants as $p) {
                $email = isset($p['email']) ? strtolower($p['email']) : null;
                $appt->participants()->create([
                    'name'         => $p['name'],
                    'email'        => $email,
                    // Pre-link an existing account so the invite shows up in their app.
                    'user_id'      => $email ? User::where('email', $email)->value('id') : null,
                    'role'         => $format === 'couples' ? 'partner' : 'family_member',
                    'invite_token' => Str::random(48),
                    'status'       => 'invited',
                ]);
            }

            if ($priceCents > 0) {
                $this->wallet->debit($client, $priceCents, $currency, 'payment', $appt);
            }

            return $appt;
        });

        // Confirmation, reminders and invitations go out after the booking is committed.
        $client->notify(new \App\Notifications\BookingConfirmedNotification($appt));
        SendAppointmentReminderJob::dispatch($appt->id, 'reminder_24h')->delay($startUtc->subHours(24));
        SendAppointmentReminderJob::dispatch($appt->id, 'reminder_1h')->delay($startUtc->subHour());

        foreach ($appt->participants as $participant) {
            if ($participant->email) {
                Notification::route('mail', $participant->email)
                    ->notify(new SessionInviteNotification($appt, $participant, $client->name));
            }
        }

        return response()->json((new AppointmentResource($appt->fresh(self::WITH)))->toArray($request), 201);
    }

    /**
     * Work out the care format, the dependent it is for, and any invited
     * participants — and check the professional actually offers that.
     *
     * @return array{0:string, 1:?Dependent, 2:array<int, array{name:string, email?:string}>}
     */
    private function resolveCare(StoreAppointmentRequest $request, User $client, ProfessionalProfile $profile): array
    {
        $dependent = null;
        if ($depId = $request->input('dependent_id')) {
            $dependent = Dependent::where('guardian_user_id', $client->id)->find($depId);
            if (! $dependent) {
                throw ValidationException::withMessages(['dependent_id' => ['Choose one of the children on your account.']]);
            }
        }

        // Booking for a child implies the child/teen format unless it is a family session.
        $format = $request->input('care_format')
            ?: ($dependent ? ($dependent->ageGroup() === 'children' ? 'child' : 'teen') : 'individual');
        $participants = $request->input('participants', []);

        if (! $profile->offersFormat($format)) {
            throw ValidationException::withMessages([
                'care_format' => ["This professional does not offer {$format} sessions."],
            ]);
        }

        switch ($format) {
            case 'child':
            case 'teen':
                if (! $dependent) {
                    throw ValidationException::withMessages(['dependent_id' => ['Choose which child this session is for.']]);
                }
                $group = $dependent->ageGroup();
                if (($format === 'child' && $group !== 'children') || ($format === 'teen' && $group !== 'teens')) {
                    throw ValidationException::withMessages([
                        'care_format' => ["{$dependent->name} is {$dependent->age()}: book a ".($group === 'children' ? 'child' : 'teen').' session instead.'],
                    ]);
                }
                if (! $profile->servesAgeGroup($group)) {
                    throw ValidationException::withMessages([
                        'dependent_id' => ['This professional does not work with this age group.'],
                    ]);
                }
                $participants = [];
                break;

            case 'couples':
                if (count($participants) !== 1) {
                    throw ValidationException::withMessages(['participants' => ['Add your partner to book couples counselling.']]);
                }
                if ($dependent) {
                    throw ValidationException::withMessages(['dependent_id' => ['Couples sessions are for two adults.']]);
                }
                break;

            case 'family':
                if ($dependent && ! $profile->servesAgeGroup($dependent->ageGroup())) {
                    throw ValidationException::withMessages([
                        'dependent_id' => ['This professional does not work with this age group.'],
                    ]);
                }
                break;

            default: // individual
                if ($dependent) {
                    throw ValidationException::withMessages(['care_format' => ['Use a child or teen session when booking for a dependent.']]);
                }
                if (! $profile->servesAgeGroup('adults')) {
                    throw ValidationException::withMessages(['care_format' => ['This professional works with children and teens only.']]);
                }
                $participants = [];
        }

        foreach ($participants as $p) {
            if (isset($p['email']) && strtolower($p['email']) === strtolower($client->email)) {
                throw ValidationException::withMessages(['participants' => ['You are already in this session — add the other person.']]);
            }
        }

        return [$format, $dependent, $participants];
    }

    /**
     * PUT /api/appointments/{id}/reschedule
     */
    public function reschedule(RescheduleAppointmentRequest $request, int $id): JsonResponse
    {
        $appt = Appointment::findOrFail($id);
        $this->authorizeAccess($request->user(), $appt, requireClient: true);
        abort_unless(in_array($appt->status, ['pending', 'confirmed', 'rescheduled'], true), 422, 'Cannot reschedule in current status.');

        $tz       = $request->input('user_timezone') ?: $appt->user_timezone ?: 'UTC';
        $newStart = CarbonImmutable::parse($request->input('scheduled_at'))->setTimezone($tz)->setTimezone('UTC');
        $duration = $appt->duration_minutes;

        if ($newStart->isPast()) {
            throw ValidationException::withMessages(['scheduled_at' => ['Cannot reschedule to the past.']]);
        }
        if ($appt->recipe_id) {
            // Moving a cooking session still has to leave time to shop.
            $this->cooking->requireLeadTime($newStart);
        }

        DB::transaction(function () use ($appt, $newStart, $duration) {
            if (! $this->slots->isSlotBookable($appt->professional, $newStart, $duration)) {
                throw ValidationException::withMessages(['scheduled_at' => ['New slot is not available.']]);
            }
            // Stays `confirmed`: a moved session still occupies its (new) slot.
            $appt->update(['scheduled_at' => $newStart, 'status' => 'confirmed']);
            // re-arm reminders
            SendAppointmentReminderJob::dispatch($appt->id, 'reminder_24h')->delay($newStart->subHours(24));
            SendAppointmentReminderJob::dispatch($appt->id, 'reminder_1h')->delay($newStart->subHour());
        });

        return response()->json((new AppointmentResource($appt->fresh()))->toArray($request));
    }

    /**
     * PUT /api/appointments/{id}/cancel
     *
     * Client cancels: full refund 24h+ before, 50% between 24h and 2h,
     * nothing inside 2h. Professional (or support) cancels: always a full
     * refund. Whatever is kept goes to the professional as a late-cancel fee.
     */
    public function cancel(CancelAppointmentRequest $request, int $id): JsonResponse
    {
        $appt = Appointment::findOrFail($id);
        $user = $request->user();
        $this->authorizeAccess($user, $appt, manage: true);
        abort_unless(in_array($appt->status, ['pending', 'confirmed', 'rescheduled'], true), 422, 'Cannot cancel in current status.');

        $byClient   = $user->id === $appt->user_id;
        $hoursUntil = $appt->scheduled_at ? now()->diffInHours($appt->scheduled_at, false) : 0;
        $policy = match (true) {
            ! $byClient       => 'full_refund',
            $hoursUntil >= 24 => 'full_refund',
            $hoursUntil >= 2  => 'partial_refund_50',
            default           => 'no_refund',
        };
        $refundCents = match ($policy) {
            'full_refund'       => $appt->price_cents,
            'partial_refund_50' => intdiv($appt->price_cents, 2),
            default             => 0,
        };

        DB::transaction(function () use ($appt, $request, $user, $policy, $refundCents) {
            $appt->update([
                'status'              => 'cancelled',
                'cancelled_at'        => now(),
                'cancelled_by'        => $user->id,
                'cancellation_reason' => $request->input('reason') ?: $policy,
                'refunded_cents'      => $refundCents,
            ]);

            if ($refundCents > 0) {
                $this->wallet->credit($appt->client, $refundCents, $appt->currency, 'refund', $appt, $policy);
            }
            $kept = $appt->price_cents - $refundCents;
            if ($kept > 0) {
                $this->earnings->record($appt->professional, 'session', $kept, $appt, $appt->currency);
            }
        });

        return response()->json([
            'message'        => 'Appointment cancelled.',
            'refund_policy'  => $policy,
            'refunded_cents' => $refundCents,
            'appointment'    => (new AppointmentResource($appt->fresh(self::WITH)))->resolve($request),
        ]);
    }

    /**
     * POST /api/appointments/{id}/ingredients/confirm
     * The client confirms they have what the recipe needs. Required before
     * joining a cooking session.
     */
    public function confirmIngredients(Request $request, int $id): JsonResponse
    {
        $appt = Appointment::findOrFail($id);
        abort_unless($request->user()->id === $appt->user_id, 403, 'Only the person who booked can confirm.');
        abort_unless($appt->recipe_id, 422, 'This session has no recipe.');

        $appt->update(['ingredients_confirmed_at' => now()]);

        return response()->json((new AppointmentResource($appt->fresh(self::WITH)))->toArray($request));
    }

    /**
     * GET /api/appointment-invites
     * Couples / family sessions someone has invited me to.
     */
    public function invites(Request $request): JsonResponse
    {
        $user = $request->user();
        $invites = AppointmentParticipant::with(['appointment.client', 'appointment.professional'])
            ->where('status', 'invited')
            ->where(fn ($q) => $q->where('user_id', $user->id)->orWhere('email', strtolower($user->email)))
            ->whereHas('appointment', fn ($a) => $a->whereIn('status', ['pending', 'confirmed', 'rescheduled']))
            ->get();

        return response()->json(['data' => $invites->map(fn ($i) => [
            'id'             => $i->id,
            'role'           => $i->role,
            'appointment_id' => $i->appointment_id,
            'care_format'    => $i->appointment->care_format,
            'scheduled_at'   => $i->appointment->scheduled_at?->toIso8601String(),
            'invited_by'     => $i->appointment->client?->name,
            'professional'   => $i->appointment->professional?->name,
        ])]);
    }

    /**
     * POST /api/appointment-invites/accept   { token } or { invite_id }
     * POST /api/appointment-invites/decline
     * The invite belongs to whoever holds the emailed token, or to the
     * account whose email it was sent to.
     */
    public function respondToInvite(Request $request, string $action): JsonResponse
    {
        abort_unless(in_array($action, ['accept', 'decline'], true), 404);
        $user = $request->user();
        $data = $request->validate([
            'token'     => ['required_without:invite_id', 'string', 'max:64'],
            'invite_id' => ['required_without:token', 'integer'],
        ]);

        $invite = isset($data['token'])
            ? AppointmentParticipant::where('invite_token', $data['token'])->first()
            : AppointmentParticipant::whereKey($data['invite_id'])
                ->where(fn ($q) => $q->where('user_id', $user->id)->orWhere('email', strtolower($user->email)))
                ->first();
        abort_unless($invite, 404, 'Invitation not found.');
        abort_if($invite->user_id && $invite->user_id !== $user->id, 403, 'This invitation belongs to another account.');
        abort_if($invite->appointment->professional_user_id === $user->id, 422, 'You are hosting this session.');

        if ($action === 'accept') {
            // Joining someone's couples or family session is an adult's decision.
            AgeGate::requireMinAge($user, (int) config('akilil.adult_age'), 'join this session with your own account');
            $invite->update(['user_id' => $user->id, 'status' => 'accepted', 'accepted_at' => now()]);
        } else {
            $invite->update(['user_id' => $user->id, 'status' => 'declined']);
        }

        return response()->json([
            'message'        => $action === 'accept' ? 'You are in. The session is now in your list.' : 'Invitation declined.',
            'appointment_id' => $invite->appointment_id,
            'status'         => $invite->status,
        ]);
    }

    /**
     * Viewing: anyone in the session (or support). Managing — reschedule,
     * cancel — is for the account holder who booked and the professional.
     */
    private function authorizeAccess(User $user, Appointment $appt, bool $requireClient = false, bool $manage = false): void
    {
        $isAdmin = method_exists($user, 'hasAnyRole') && $user->hasAnyRole(['admin', 'support']);
        $isOwner = $user->id === $appt->user_id || $user->id === $appt->professional_user_id;

        if ($manage || $requireClient) {
            abort_unless($isOwner || $isAdmin, 403, 'Not your appointment.');
        } else {
            abort_unless($isAdmin || $appt->canBeJoinedBy($user), 403, 'Not your appointment.');
        }

        if ($requireClient && $user->id !== $appt->user_id) {
            abort(403, 'Only the client can perform this action.');
        }
    }
}
