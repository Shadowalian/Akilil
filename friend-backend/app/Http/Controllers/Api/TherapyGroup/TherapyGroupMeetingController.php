<?php

namespace App\Http\Controllers\Api\TherapyGroup;

use App\Http\Controllers\Controller;
use App\Http\Resources\TherapyGroupMeetingResource;
use App\Models\TherapyGroup;
use App\Models\TherapyGroupMeeting;
use App\Models\TherapyGroupMeetingSeat;
use App\Models\TherapyGroupMember;
use App\Models\User;
use App\Services\CookingRules;
use App\Services\EarningsService;
use App\Services\JitsiService;
use App\Services\WalletService;
use App\Support\AgeGate;
use Carbon\CarbonImmutable;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

/**
 * Meetings of a group: group therapy, a spiritual circle, or a cooking
 * class. Members reserve (and pay for) a seat per meeting; the host is
 * paid when the meeting ends; everyone is refunded if the host cancels.
 */
class TherapyGroupMeetingController extends Controller
{
    public function __construct(
        private JitsiService $jitsi,
        private WalletService $wallet,
        private EarningsService $earnings,
        private CookingRules $cooking,
    ) {}

    /** GET /api/therapy-groups/{id}/meetings */
    public function index(Request $request, int $id): JsonResponse
    {
        $group = TherapyGroup::findOrFail($id);
        $user = $request->user();
        $this->authorizeGroupAccess($user, $group);

        $meetings = TherapyGroupMeeting::where('therapy_group_id', $group->id)
            ->with(['recipe'])
            ->withCount('reservedSeats')
            ->orderByDesc('scheduled_at')
            ->limit(50)
            ->get();

        $mySeats = TherapyGroupMeetingSeat::whereIn('therapy_group_meeting_id', $meetings->pluck('id'))
            ->where('user_id', $user->id)->get()->keyBy('therapy_group_meeting_id');
        $meetings->each(fn ($m) => $m->setRelation('mySeat', $mySeats->get($m->id)));

        return response()->json([
            'data' => TherapyGroupMeetingResource::collection($meetings)->resolve($request),
        ]);
    }

    /** POST /api/therapy-groups/{id}/meetings */
    public function store(Request $request, int $id): JsonResponse
    {
        $user = $request->user();
        $group = TherapyGroup::with('category')->findOrFail($id);
        abort_unless((int) $user->id === (int) $group->professional_user_id, 403, 'Only the host can schedule.');
        abort_unless($group->status === 'active', 422, 'Group is archived.');

        $data = $request->validate([
            'title' => ['nullable', 'string', 'max:160'],
            'scheduled_at' => ['required', 'date', 'after:now'],
            'duration_minutes' => ['nullable', 'integer', 'min:15', 'max:240'],
            'price_cents' => ['nullable', 'integer', 'min:0'],
            'recipe_id' => ['nullable', 'integer'],
        ]);
        $startsAt = CarbonImmutable::parse($data['scheduled_at'])->utc();

        // A cooking class always has a recipe and leaves time to shop.
        $recipe = null;
        if ($group->isCookingClass()) {
            $recipe = $this->cooking->requireRecipe($user, $data['recipe_id'] ?? null);
            $this->cooking->requireLeadTime($startsAt);
        }

        $meeting = TherapyGroupMeeting::create([
            'therapy_group_id' => $group->id,
            'title' => $data['title'] ?? ($recipe ? $recipe->title : $group->title),
            'scheduled_at' => $startsAt,
            'duration_minutes' => $data['duration_minutes'] ?? 60,
            'price_cents' => $data['price_cents'] ?? $group->price_cents,
            'currency' => $group->currency,
            'recipe_id' => $recipe?->id,
            'status' => 'scheduled',
        ]);

        return response()->json([
            'message' => 'Meeting scheduled.',
            'meeting' => $this->present($meeting, $request),
        ], 201);
    }

    /**
     * POST /api/therapy-group-meetings/{id}/reserve
     * A member takes (and pays for) a seat.
     */
    public function reserve(Request $request, int $id): JsonResponse
    {
        $user = $request->user();
        $meeting = TherapyGroupMeeting::with('group')->findOrFail($id);
        $group = $meeting->group;

        abort_unless($this->isMember($user, $group), 403, 'Join the group first.');
        abort_unless($meeting->status === 'scheduled' || $meeting->status === 'live', 422, 'This meeting is not open for booking.');
        AgeGate::requireMinAge($user, (int) $group->min_age, 'join this group');
        if ($meeting->price_cents > 0) {
            AgeGate::requireAdultPayer($user);
        }

        $existing = TherapyGroupMeetingSeat::where('therapy_group_meeting_id', $meeting->id)
            ->where('user_id', $user->id)->first();
        if ($existing && $existing->status === 'reserved') {
            return response()->json(['message' => 'You already have a seat.', 'meeting' => $this->present($meeting, $request)]);
        }

        if ($meeting->price_cents > 0 && ! $this->wallet->canAfford($user, $meeting->price_cents, $meeting->currency)) {
            return response()->json([
                'message'        => 'Insufficient wallet balance',
                'required_cents' => $meeting->price_cents,
                'balance_cents'  => $this->wallet->walletFor($user)->balance_cents,
                'currency'       => $meeting->currency,
            ], 402);
        }

        DB::transaction(function () use ($meeting, $group, $user, $existing) {
            // Lock the meeting row so the last seat can't be sold twice.
            TherapyGroupMeeting::whereKey($meeting->id)->lockForUpdate()->first();
            $taken = TherapyGroupMeetingSeat::where('therapy_group_meeting_id', $meeting->id)
                ->where('status', 'reserved')->count();
            if ($taken >= $group->max_members) {
                throw ValidationException::withMessages(['meeting' => ['This meeting is full.']]);
            }

            $seat = $existing ?? new TherapyGroupMeetingSeat([
                'therapy_group_meeting_id' => $meeting->id,
                'user_id' => $user->id,
            ]);
            $seat->fill([
                'status' => 'reserved',
                'price_cents' => $meeting->price_cents,
                'currency' => $meeting->currency,
                'ingredients_confirmed_at' => null,
            ])->save();

            if ($meeting->price_cents > 0) {
                $tx = $this->wallet->debit($user, $meeting->price_cents, $meeting->currency, 'payment', $seat);
                $seat->update(['transaction_id' => $tx->id]);
            }
        });

        return response()->json([
            'message' => 'Seat reserved.',
            'meeting' => $this->present($meeting, $request),
        ], 201);
    }

    /**
     * POST /api/therapy-group-meetings/{id}/cancel-seat
     * Full refund up to 24h before; after that the seat is forfeited.
     */
    public function cancelSeat(Request $request, int $id): JsonResponse
    {
        $user = $request->user();
        $meeting = TherapyGroupMeeting::findOrFail($id);
        $seat = TherapyGroupMeetingSeat::where('therapy_group_meeting_id', $meeting->id)
            ->where('user_id', $user->id)->where('status', 'reserved')->first();
        abort_unless($seat, 422, 'You have no seat for this meeting.');
        abort_unless($meeting->status === 'scheduled', 422, 'This meeting has already started.');

        $refundable = now()->diffInHours($meeting->scheduled_at, false) >= 24;

        DB::transaction(function () use ($seat, $user, $refundable) {
            if ($refundable && $seat->price_cents > 0) {
                $this->wallet->credit($user, $seat->price_cents, $seat->currency, 'refund', $seat, 'seat_cancelled');
                $seat->update(['status' => 'refunded']);
            } else {
                $seat->update(['status' => 'cancelled']);
            }
        });

        return response()->json([
            'message' => $refundable ? 'Seat cancelled and refunded.' : 'Seat cancelled. Inside 24 hours seats are not refundable.',
            'refunded_cents' => $refundable ? $seat->price_cents : 0,
        ]);
    }

    /** POST /api/therapy-group-meetings/{id}/ingredients/confirm */
    public function confirmIngredients(Request $request, int $id): JsonResponse
    {
        $meeting = TherapyGroupMeeting::findOrFail($id);
        abort_unless($meeting->recipe_id, 422, 'This meeting has no recipe.');
        $seat = TherapyGroupMeetingSeat::where('therapy_group_meeting_id', $meeting->id)
            ->where('user_id', $request->user()->id)->where('status', 'reserved')->first();
        abort_unless($seat, 422, 'Reserve your seat first.');

        $seat->update(['ingredients_confirmed_at' => now()]);

        return response()->json(['message' => 'Ready to cook.', 'meeting' => $this->present($meeting, $request)]);
    }

    /** POST /api/therapy-group-meetings/{id}/start — host opens the room. */
    public function start(Request $request, int $id): JsonResponse
    {
        $user = $request->user();
        $meeting = TherapyGroupMeeting::with('group')->findOrFail($id);
        $group = $meeting->group;
        abort_unless((int) $user->id === (int) $group->professional_user_id, 403, 'Only the host can start.');
        abort_unless(in_array($meeting->status, ['scheduled', 'live'], true), 422, 'Meeting cannot be started.');

        if ($meeting->recipe_id && $meeting->status === 'scheduled') {
            $this->cooking->requireNotTooEarly($meeting->scheduled_at);
        }

        if (! $meeting->room_name) {
            $meeting->room_name = $this->jitsi->newRoomName('group', $meeting->id);
        }
        $meeting->status = 'live';
        $meeting->started_at = $meeting->started_at ?? now();
        $meeting->save();

        return response()->json([
            'session' => $this->jitsi->sessionFor($user, $meeting->room_name, 'group', true),
            'display_name' => $user->name,
            'meeting' => $this->present($meeting, $request),
        ]);
    }

    /**
     * POST /api/therapy-group-meetings/{id}/join — a member enters the
     * live room. Needs a seat (free meetings seat you automatically) and,
     * for a cooking class, confirmed ingredients.
     */
    public function join(Request $request, int $id): JsonResponse
    {
        $user = $request->user();
        $meeting = TherapyGroupMeeting::with('group')->findOrFail($id);
        $group = $meeting->group;

        $isHost = (int) $user->id === (int) $group->professional_user_id;
        abort_unless($isHost || $this->isMember($user, $group), 403, 'Not a group member.');

        if ($meeting->status !== 'live' || ! $meeting->room_name) {
            throw ValidationException::withMessages([
                'status' => ['The host has not started this meeting yet.'],
            ]);
        }

        if (! $isHost) {
            $seat = TherapyGroupMeetingSeat::where('therapy_group_meeting_id', $meeting->id)
                ->where('user_id', $user->id)->first();

            if ((! $seat || $seat->status !== 'reserved') && $meeting->price_cents > 0) {
                return response()->json([
                    'message' => 'Reserve your seat to join this meeting.',
                    'code'    => 'seat_required',
                    'price_cents' => $meeting->price_cents,
                    'currency' => $meeting->currency,
                ], 402);
            }
            if (! $seat || $seat->status !== 'reserved') {
                AgeGate::requireMinAge($user, (int) $group->min_age, 'join this group');
                $seat = TherapyGroupMeetingSeat::updateOrCreate(
                    ['therapy_group_meeting_id' => $meeting->id, 'user_id' => $user->id],
                    ['status' => 'reserved', 'price_cents' => 0, 'currency' => $meeting->currency],
                );
            }
            if ($meeting->recipe_id && ! $seat->ingredients_confirmed_at) {
                return response()->json([
                    'message'   => 'Confirm you have the ingredients before joining.',
                    'code'      => 'ingredients_required',
                    'recipe_id' => $meeting->recipe_id,
                ], 422);
            }
            $seat->update(['joined_at' => $seat->joined_at ?? now()]);
        }

        return response()->json([
            'session' => $this->jitsi->sessionFor($user, $meeting->room_name, 'group', $isHost),
            'display_name' => $user->name,
            'meeting' => $this->present($meeting, $request),
        ]);
    }

    /** POST /api/therapy-group-meetings/{id}/end — host closes; earnings are booked. */
    public function end(Request $request, int $id): JsonResponse
    {
        $user = $request->user();
        $meeting = TherapyGroupMeeting::with('group.professional')->findOrFail($id);
        abort_unless((int) $user->id === (int) $meeting->group->professional_user_id, 403, 'Only the host can end.');
        abort_unless(in_array($meeting->status, ['live', 'ended'], true), 422, 'Meeting is not live.');

        DB::transaction(function () use ($meeting) {
            $meeting->update(['status' => 'ended', 'ended_at' => $meeting->ended_at ?? now()]);
            // Every paid, reserved seat becomes income for the host.
            foreach ($meeting->reservedSeats()->where('price_cents', '>', 0)->get() as $seat) {
                $this->earnings->record($meeting->group->professional, 'group_seat', $seat->price_cents, $seat, $seat->currency);
            }
        });

        return response()->json(['message' => 'Meeting ended.', 'meeting' => $this->present($meeting, $request)]);
    }

    /** POST /api/therapy-group-meetings/{id}/cancel — host cancels; all seats refunded. */
    public function cancel(Request $request, int $id): JsonResponse
    {
        $user = $request->user();
        $meeting = TherapyGroupMeeting::with('group')->findOrFail($id);
        abort_unless((int) $user->id === (int) $meeting->group->professional_user_id, 403, 'Only the host can cancel.');
        abort_unless($meeting->status === 'scheduled', 422, 'Only a scheduled meeting can be cancelled.');

        DB::transaction(function () use ($meeting) {
            $meeting->update(['status' => 'cancelled']);
            foreach ($meeting->reservedSeats()->with('user')->get() as $seat) {
                if ($seat->price_cents > 0 && $seat->user) {
                    $this->wallet->credit($seat->user, $seat->price_cents, $seat->currency, 'refund', $seat, 'meeting_cancelled');
                }
                $seat->update(['status' => 'refunded']);
            }
        });

        return response()->json(['message' => 'Meeting cancelled. Everyone has been refunded.']);
    }

    /* ------------------------------------------------------------------ */

    private function present(TherapyGroupMeeting $meeting, Request $request): array
    {
        $meeting = $meeting->fresh(['recipe'])->loadCount('reservedSeats');
        $meeting->setRelation('mySeat', TherapyGroupMeetingSeat::where('therapy_group_meeting_id', $meeting->id)
            ->where('user_id', $request->user()->id)->first());

        return (new TherapyGroupMeetingResource($meeting))->toArray($request);
    }

    private function isMember(User $user, TherapyGroup $group): bool
    {
        return TherapyGroupMember::where('therapy_group_id', $group->id)
            ->where('user_id', $user->id)
            ->where('status', 'active')
            ->exists();
    }

    private function authorizeGroupAccess(User $user, TherapyGroup $group): void
    {
        $isHost = (int) $user->id === (int) $group->professional_user_id;
        abort_unless(
            $isHost || $this->isMember($user, $group) || ($group->is_open && $group->status === 'active'),
            403,
            'Group is not available.'
        );
    }
}
