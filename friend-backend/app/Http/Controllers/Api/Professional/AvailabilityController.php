<?php

namespace App\Http\Controllers\Api\Professional;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\Availability\AvailableSlotsRequest;
use App\Http\Requests\Api\Availability\StoreAvailabilityBlockRequest;
use App\Http\Requests\Api\Availability\StoreAvailabilityRuleRequest;
use App\Http\Requests\Api\Availability\UpdateAvailabilityRuleRequest;
use App\Http\Resources\AvailabilityBlockResource;
use App\Http\Resources\AvailabilityRuleResource;
use App\Models\AvailabilityBlock;
use App\Models\AvailabilitySlotRule;
use App\Models\ProfessionalProfile;
use App\Models\User;
use App\Services\SlotService;
use Carbon\CarbonImmutable;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AvailabilityController extends Controller
{
    public function __construct(private SlotService $slots) {}

    /**
     * GET /api/professional/availability
     * Auth: professional only. Returns all rules + upcoming blocks.
     */
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        abort_unless($user->role === 'professional', 403, 'Only professionals can manage availability.');

        $rules  = $user->availabilitySlotRules()->orderBy('weekday')->orderBy('start_time')->get();
        $blocks = $user->availabilityBlocks()->where('end_at', '>=', now())->orderBy('start_at')->get();

        return response()->json([
            'rules'  => AvailabilityRuleResource::collection($rules)->resolve($request),
            'blocks' => AvailabilityBlockResource::collection($blocks)->resolve($request),
        ]);
    }

    public function storeRule(StoreAvailabilityRuleRequest $request): JsonResponse
    {
        $user = $request->user();
        abort_unless($user->role === 'professional', 403);
        $data = $request->validated();
        $data['is_active'] = $data['is_active'] ?? true;
        $rule = $user->availabilitySlotRules()->create($data);
        return (new AvailabilityRuleResource($rule->fresh()))->response()->setStatusCode(201);
    }

    public function updateRule(UpdateAvailabilityRuleRequest $request, int $id): JsonResponse
    {
        $user = $request->user();
        abort_unless($user->role === 'professional', 403);
        $rule = $user->availabilitySlotRules()->findOrFail($id);
        $rule->update($request->validated());
        return (new AvailabilityRuleResource($rule->fresh()))->response();
    }

    public function destroyRule(Request $request, int $id): JsonResponse
    {
        $user = $request->user();
        abort_unless($user->role === 'professional', 403);
        $user->availabilitySlotRules()->findOrFail($id)->delete();
        return response()->json(['message' => 'Rule removed.']);
    }

    public function storeBlock(StoreAvailabilityBlockRequest $request): JsonResponse
    {
        $user = $request->user();
        abort_unless($user->role === 'professional', 403);
        $block = $user->availabilityBlocks()->create($request->validated());
        return (new AvailabilityBlockResource($block))->response()->setStatusCode(201);
    }

    public function destroyBlock(Request $request, int $id): JsonResponse
    {
        $user = $request->user();
        abort_unless($user->role === 'professional', 403);
        $user->availabilityBlocks()->findOrFail($id)->delete();
        return response()->json(['message' => 'Block removed.']);
    }

    /**
     * GET /api/professionals/{id}/available-slots
     * Public — anyone (even unauthenticated) can query a pro's bookable slots.
     *
     * Clients send either a professional_profiles.id or a users.id here, so
     * the id is resolved against both before we give up.
     */
    public function availableSlots(AvailableSlotsRequest $request, int $professionalId): JsonResponse
    {
        $professional = ProfessionalProfile::find($professionalId)?->user
            ?: User::where('role', 'professional')->findOrFail($professionalId);

        $profile = $professional->professionalProfile;
        abort_unless($profile?->is_accepting_clients, 404, 'Professional not accepting clients.');

        $tz = $request->input('timezone') ?: $request->user()?->timezone ?: 'UTC';
        // Parse as a calendar date in the requester's timezone (avoid shifting the day).
        $day = CarbonImmutable::createFromFormat(
            'Y-m-d',
            (string) $request->input('date'),
            $tz
        )->startOfDay();
        $duration = (int) ($request->input('duration_minutes') ?: $profile->session_duration_minutes);

        return response()->json([
            'professional_user_id'    => $professional->id,
            'professional_profile_id' => $profile->id,
            'date'                  => $day->toDateString(),
            'timezone'              => $tz,
            'duration_minutes'      => $duration,
            'slots'                 => $this->slots->forDay($professional, $day, $tz, $duration),
        ]);
    }

    /**
     * GET /api/professional/availability/blocks
     * The blocks half of index(), for clients that only need the blocks.
     */
    public function indexBlocks(Request $request): JsonResponse
    {
        $user = $request->user();
        abort_unless($user->role === 'professional', 403, 'Only professionals can manage availability.');

        $blocks = $user->availabilityBlocks()->where('end_at', '>=', now())->orderBy('start_at')->get();

        return response()->json([
            'data' => AvailabilityBlockResource::collection($blocks)->resolve($request),
        ]);
    }
}