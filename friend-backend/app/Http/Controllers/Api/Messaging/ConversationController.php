<?php

namespace App\Http\Controllers\Api\Messaging;

use App\Http\Controllers\Controller;
use App\Http\Resources\ConversationResource;
use App\Models\Conversation;
use App\Models\ConversationParticipant;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class ConversationController extends Controller
{
    /**
     * GET /api/conversations
     * Auth user's conversation list with last message + unread count.
     */
    public function index(Request $request): JsonResponse
    {
        $userId = $request->user()->id;
        $rows = Conversation::with(['participants.user', 'messages' => fn ($q) => $q->latest()->limit(1)])
            ->whereHas('participants', fn ($q) => $q->where('user_id', $userId))
            ->orderByDesc('last_message_at')
            ->paginate((int) $request->query('per_page', 20));

        return response()->json([
            'data' => ConversationResource::collection($rows->items())->resolve($request),
            'meta' => [
                'current_page' => $rows->currentPage(),
                'last_page'    => $rows->lastPage(),
                'per_page'     => $rows->perPage(),
                'total'        => $rows->total(),
            ],
        ]);
    }

    /**
     * POST /api/conversations
     * Body for direct: { participant_user_id: int }
     * Body for group:  { title: string, participant_user_ids: [int,...] }
     */
    public function store(Request $request): JsonResponse
    {
        $user = $request->user();
        $type = $request->input('type', 'direct');

        if ($type === 'direct') {
            $request->validate([
                'participant_user_id' => ['required', 'integer', 'exists:users,id', 'different:' . $user->id],
            ]);
            $other = (int) $request->input('participant_user_id');
            // Idempotent: return existing 1:1 if present.
            $existing = Conversation::where('type', 'direct')
                ->whereHas('participants', fn ($q) => $q->where('user_id', $user->id))
                ->whereHas('participants', fn ($q) => $q->where('user_id', $other))
                ->first();
            if ($existing) {
                return response()->json((new ConversationResource($existing->load('participants.user')))->toArray($request), 200);
            }
            return DB::transaction(function () use ($user, $other) {
                $conv = Conversation::create(['type' => 'direct', 'created_by' => $user->id]);
                ConversationParticipant::create(['conversation_id' => $conv->id, 'user_id' => $user->id, 'joined_at' => now()]);
                ConversationParticipant::create(['conversation_id' => $conv->id, 'user_id' => $other, 'joined_at' => now()]);
                return response()->json((new ConversationResource($conv->load('participants.user')))->toArray($request), 201);
            });
        }

        // Group
        $data = $request->validate([
            'title'                  => ['required', 'string', 'max:191'],
            'participant_user_ids'   => ['required', 'array', 'min:2', 'max:50'],
            'participant_user_ids.*' => ['integer', 'exists:users,id'],
        ]);

        return DB::transaction(function () use ($user, $data) {
            $conv = Conversation::create([
                'type'       => 'group',
                'title'      => $data['title'],
                'created_by' => $user->id,
            ]);
            ConversationParticipant::create([
                'conversation_id' => $conv->id, 'user_id' => $user->id,
                'role' => 'admin', 'joined_at' => now(),
            ]);
            foreach (array_unique($data['participant_user_ids']) as $uid) {
                if ((int) $uid === $user->id) continue;
                ConversationParticipant::create([
                    'conversation_id' => $conv->id, 'user_id' => $uid, 'joined_at' => now(),
                ]);
            }
            return response()->json((new ConversationResource($conv->load('participants.user')))->toArray($request), 201);
        });
    }

    /**
     * GET /api/conversations/{id}
     */
    public function show(Request $request, int $id): JsonResponse
    {
        $conv = Conversation::with('participants.user')->findOrFail($id);
        abort_unless($conv->participants->contains('user_id', $request->user()->id), 403, 'Not a participant.');
        return response()->json((new ConversationResource($conv))->toArray($request));
    }

    public function markRead(Request $request, int $id): JsonResponse
    {
        $userId = $request->user()->id;
        $conv = Conversation::findOrFail($id);
        $participant = ConversationParticipant::where('conversation_id', $conv->id)
            ->where('user_id', $userId)
            ->firstOrFail();
        $participant->update([
            'last_read_at' => now(),
            'last_read_message_id' => $conv->last_message_id ?? $participant->last_read_message_id,
        ]);
        return response()->json(['ok' => true]);
    }
}