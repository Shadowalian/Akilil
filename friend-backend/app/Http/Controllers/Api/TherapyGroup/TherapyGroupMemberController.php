<?php

namespace App\Http\Controllers\Api\TherapyGroup;

use App\Http\Controllers\Controller;
use App\Http\Resources\TherapyGroupResource;
use App\Models\TherapyGroup;
use App\Models\TherapyGroupMember;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;

class TherapyGroupMemberController extends Controller
{
    /**
     * POST /api/therapy-groups/{id}/join
     */
    public function join(Request $request, int $id): JsonResponse
    {
        $user = $request->user();
        abort_unless($user->role === 'user', 403, 'Only clients can join groups.');

        $group = TherapyGroup::withCount('activeMembers')->findOrFail($id);
        abort_unless($group->status === 'active' && $group->is_open, 422, 'This group is not open for joining.');
        abort_unless(
            $group->active_members_count < $group->max_members,
            422,
            'This group is full.'
        );

        $member = TherapyGroupMember::firstOrNew([
            'therapy_group_id' => $group->id,
            'user_id' => $user->id,
        ]);
        if ($member->exists && $member->status === 'active') {
            throw ValidationException::withMessages([
                'group' => ['You are already a member of this group.'],
            ]);
        }
        $member->status = 'active';
        $member->joined_at = now();
        $member->save();

        $group->load('professional')->loadCount('activeMembers');
        $group->is_member = true;

        return response()->json([
            'message' => 'Joined group.',
            'group' => (new TherapyGroupResource($group))->toArray($request),
        ]);
    }

    /**
     * POST /api/therapy-groups/{id}/leave
     */
    public function leave(Request $request, int $id): JsonResponse
    {
        $user = $request->user();
        $group = TherapyGroup::findOrFail($id);
        $member = TherapyGroupMember::where('therapy_group_id', $group->id)
            ->where('user_id', $user->id)
            ->where('status', 'active')
            ->first();
        abort_unless($member, 422, 'You are not an active member.');

        $member->update(['status' => 'left']);

        return response()->json(['message' => 'Left group.']);
    }
}
