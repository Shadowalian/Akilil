<?php

namespace App\Http\Controllers\Api\TherapyGroup;

use App\Http\Controllers\Controller;
use App\Http\Resources\TherapyGroupResource;
use App\Models\TherapyGroup;
use App\Models\TherapyGroupMember;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class TherapyGroupController extends Controller
{
    /**
     * GET /api/therapy-groups
     * Clients: open active groups (optional ?professional_user_id=).
     * Pros: their own groups including archived unless ?status=active.
     */
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        $q = TherapyGroup::query()->with(['professional', 'category'])->withCount('activeMembers');

        if ($user->role === 'professional' && ! $request->boolean('discover')) {
            $q->where('professional_user_id', $user->id);
            if ($status = $request->query('status')) {
                $q->where('status', $status);
            }
        } else {
            $q->open();
            if ($proId = $request->query('professional_user_id')) {
                $q->where('professional_user_id', (int) $proId);
            }
            // Browse by pillar: group therapy, spiritual circles, cooking classes.
            if ($slug = $request->query('category')) {
                $q->whereHas('category', fn ($c) => $c->where('slug', $slug));
            }
        }

        $groups = $q->orderByDesc('id')->paginate((int) $request->query('per_page', 20));

        $memberGroupIds = TherapyGroupMember::where('user_id', $user->id)
            ->where('status', 'active')
            ->pluck('therapy_group_id')
            ->all();

        $data = collect($groups->items())->map(function (TherapyGroup $g) use ($memberGroupIds, $request) {
            $g->is_member = in_array($g->id, $memberGroupIds, true);

            return (new TherapyGroupResource($g))->toArray($request);
        });

        return response()->json([
            'data' => $data,
            'meta' => [
                'current_page' => $groups->currentPage(),
                'last_page' => $groups->lastPage(),
                'per_page' => $groups->perPage(),
                'total' => $groups->total(),
            ],
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $user = $request->user();
        abort_unless($user->role === 'professional', 403, 'Only professionals can create groups.');

        $data = $request->validate([
            'title' => ['required', 'string', 'min:2', 'max:160'],
            'description' => ['nullable', 'string', 'max:5000'],
            'max_members' => ['nullable', 'integer', 'min:2', 'max:50'],
            'is_open' => ['nullable', 'boolean'],
            'price_cents' => ['nullable', 'integer', 'min:0'],
            'min_age' => ['nullable', 'integer', 'min:0', 'max:99'],
        ]);

        $profile = $user->professionalProfile;
        abort_unless($profile && $profile->verification_status === 'approved', 403, 'Your profile must be verified before you host groups.');

        $group = TherapyGroup::create([
            'professional_user_id' => $user->id,
            // A group lives in its host's pillar.
            'category_id' => $profile->category_id,
            'min_age' => $data['min_age'] ?? (int) config('akilil.adult_age'),
            'title' => $data['title'],
            'description' => $data['description'] ?? null,
            'max_members' => $data['max_members'] ?? 12,
            'is_open' => $data['is_open'] ?? true,
            'price_cents' => $data['price_cents'] ?? 0,
            'currency' => $profile->currency ?: config('akilil.currency'),
            'status' => 'active',
        ]);

        return response()->json([
            'message' => 'Group created.',
            'group' => (new TherapyGroupResource($group->load(['professional', 'category'])->loadCount('activeMembers')))->toArray($request),
        ], 201);
    }

    public function show(Request $request, int $id): JsonResponse
    {
        $group = TherapyGroup::with(['professional', 'category'])->withCount('activeMembers')->findOrFail($id);
        $user = $request->user();
        $isHost = (int) $user->id === (int) $group->professional_user_id;
        $isMember = TherapyGroupMember::where('therapy_group_id', $group->id)
            ->where('user_id', $user->id)
            ->where('status', 'active')
            ->exists();
        abort_unless($isHost || $isMember || $group->is_open, 403, 'Group is not available.');

        $group->is_member = $isMember;

        return response()->json([
            'group' => (new TherapyGroupResource($group))->toArray($request),
        ]);
    }

    public function update(Request $request, int $id): JsonResponse
    {
        $user = $request->user();
        $group = TherapyGroup::findOrFail($id);
        abort_unless((int) $user->id === (int) $group->professional_user_id, 403, 'Only the host can update.');

        $data = $request->validate([
            'title' => ['sometimes', 'string', 'min:2', 'max:160'],
            'description' => ['nullable', 'string', 'max:5000'],
            'max_members' => ['sometimes', 'integer', 'min:2', 'max:50'],
            'is_open' => ['sometimes', 'boolean'],
            'price_cents' => ['sometimes', 'integer', 'min:0'],
            'min_age' => ['sometimes', 'integer', 'min:0', 'max:99'],
        ]);

        $group->fill($data)->save();

        return response()->json([
            'group' => (new TherapyGroupResource($group->fresh()->load(['professional', 'category'])->loadCount('activeMembers')))->toArray($request),
        ]);
    }

    public function archive(Request $request, int $id): JsonResponse
    {
        $user = $request->user();
        $group = TherapyGroup::findOrFail($id);
        abort_unless((int) $user->id === (int) $group->professional_user_id, 403, 'Only the host can archive.');

        $group->update(['status' => 'archived', 'is_open' => false]);

        return response()->json([
            'message' => 'Group archived.',
            'group' => (new TherapyGroupResource($group->fresh()->loadCount('activeMembers')))->toArray($request),
        ]);
    }
}
