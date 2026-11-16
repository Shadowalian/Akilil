<?php

namespace App\Http\Controllers\Api\TherapyGroup;

use App\Http\Controllers\Controller;
use App\Http\Resources\TherapyGroupMeetingResource;
use App\Models\TherapyGroup;
use App\Models\TherapyGroupMeeting;
use App\Models\TherapyGroupMember;
use App\Services\JitsiService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;

class TherapyGroupMeetingController extends Controller
{
    public function __construct(private JitsiService $jitsi) {}

    /**
     * GET /api/therapy-groups/{id}/meetings
     */
    public function index(Request $request, int $id): JsonResponse
    {
        $group = TherapyGroup::findOrFail($id);
        $this->authorizeGroupAccess($request->user(), $group);

        $meetings = TherapyGroupMeeting::where('therapy_group_id', $group->id)
            ->orderByDesc('scheduled_at')
            ->limit(50)
            ->get();

        return response()->json([
            'data' => TherapyGroupMeetingResource::collection($meetings)->resolve($request),
        ]);
    }

    /**
     * POST /api/therapy-groups/{id}/meetings
     */
    public function store(Request $request, int $id): JsonResponse
    {
        $user = $request->user();
        $group = TherapyGroup::findOrFail($id);
        abort_unless((int) $user->id === (int) $group->professional_user_id, 403, 'Only the host can schedule.');
        abort_unless($group->status === 'active', 422, 'Group is archived.');

        $data = $request->validate([
            'title' => ['nullable', 'string', 'max:160'],
            'scheduled_at' => ['required', 'date'],
            'duration_minutes' => ['nullable', 'integer', 'min:15', 'max:240'],
        ]);

        $meeting = TherapyGroupMeeting::create([
            'therapy_group_id' => $group->id,
            'title' => $data['title'] ?? $group->title,
            'scheduled_at' => $data['scheduled_at'],
            'duration_minutes' => $data['duration_minutes'] ?? 60,
            'status' => 'scheduled',
        ]);

        return response()->json([
            'message' => 'Meeting scheduled.',
            'meeting' => (new TherapyGroupMeetingResource($meeting))->toArray($request),
        ], 201);
    }

    /**
     * POST /api/therapy-group-meetings/{id}/start — host opens the room.
     */
    public function start(Request $request, int $id): JsonResponse
    {
        $user = $request->user();
        $meeting = TherapyGroupMeeting::with('group')->findOrFail($id);
        $group = $meeting->group;
        abort_unless((int) $user->id === (int) $group->professional_user_id, 403, 'Only the host can start.');
        abort_unless(in_array($meeting->status, ['scheduled', 'live'], true), 422, 'Meeting cannot be started.');

        if (! $meeting->room_name) {
            $meeting->room_name = sprintf(
                '%sgroup-%d-%s',
                config('jitsi.room_prefix', 'akilil-'),
                $meeting->id,
                Str::random(8)
            );
        }
        $meeting->status = 'live';
        $meeting->started_at = $meeting->started_at ?? now();
        $meeting->save();

        $token = $this->jitsi->issueToken($user, $meeting->room_name, true);

        return response()->json([
            'session' => [
                'room_url' => $this->jitsi->roomUrlFor($meeting->room_name),
                'room_name' => $meeting->room_name,
                'token' => $token,
                'is_host' => true,
                'provider' => 'jitsi',
            ],
            'display_name' => $user->name,
            'meeting' => (new TherapyGroupMeetingResource($meeting->fresh()))->toArray($request),
        ]);
    }

    /**
     * POST /api/therapy-group-meetings/{id}/join — member joins live room.
     */
    public function join(Request $request, int $id): JsonResponse
    {
        $user = $request->user();
        $meeting = TherapyGroupMeeting::with('group')->findOrFail($id);
        $group = $meeting->group;

        $isHost = (int) $user->id === (int) $group->professional_user_id;
        $isMember = TherapyGroupMember::where('therapy_group_id', $group->id)
            ->where('user_id', $user->id)
            ->where('status', 'active')
            ->exists();
        abort_unless($isHost || $isMember, 403, 'Not a group member.');

        if ($meeting->status !== 'live' || ! $meeting->room_name) {
            throw ValidationException::withMessages([
                'status' => ['The host has not started this meeting yet.'],
            ]);
        }

        $token = $this->jitsi->issueToken($user, $meeting->room_name, $isHost);

        return response()->json([
            'session' => [
                'room_url' => $this->jitsi->roomUrlFor($meeting->room_name),
                'room_name' => $meeting->room_name,
                'token' => $token,
                'is_host' => $isHost,
                'provider' => 'jitsi',
            ],
            'display_name' => $user->name,
            'meeting' => (new TherapyGroupMeetingResource($meeting))->toArray($request),
        ]);
    }

    private function authorizeGroupAccess($user, TherapyGroup $group): void
    {
        $isHost = (int) $user->id === (int) $group->professional_user_id;
        $isMember = TherapyGroupMember::where('therapy_group_id', $group->id)
            ->where('user_id', $user->id)
            ->where('status', 'active')
            ->exists();
        abort_unless($isHost || $isMember || ($group->is_open && $group->status === 'active'), 403, 'Group is not available.');
    }
}
