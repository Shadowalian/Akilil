<?php

namespace App\Http\Controllers\Api\Messaging;

use App\Events\MessageSent;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\Messaging\SendMessageRequest;
use App\Http\Resources\MessageResource;
use App\Models\Conversation;
use App\Models\ConversationParticipant;
use App\Models\Message;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;

class MessageController extends Controller
{
    /**
     * GET /api/conversations/{id}/messages
     * Cursor pagination by id descending. Mark the user's read pointer
     * to last_message_at on the way out.
     */
    public function index(Request $request, int $conversationId): JsonResponse
    {
        $user = $request->user();
        $conv = Conversation::findOrFail($conversationId);
        abort_unless($conv->participants->contains('user_id', $user->id), 403, 'Not a participant.');

        $page = Message::where('conversation_id', $conv->id)
            ->whereNull('parent_message_id')   // top-level only; replies fetched separately if needed
            ->orderByDesc('id')
            ->cursorPaginate((int) $request->query('per_page', 50));

        // mark as read up to latest
        $latestId = $page->items()[0]?->id;
        if ($latestId) {
            $p = ConversationParticipant::where('conversation_id', $conv->id)->where('user_id', $user->id)->first();
            if ($p) {
                $p->update(['last_read_message_id' => max((int) $p->last_read_message_id, $latestId), 'last_read_at' => now()]);
            }
        }

        return response()->json([
            'data' => MessageResource::collection($page->items())->resolve($request),
            'next_cursor' => $page->nextCursor()?->encode(),
        ]);
    }

    /**
     * POST /api/conversations/{id}/messages
     * Body (multipart):
     *   - message_type: text|voice|image
     *   - content: text body (when message_type=text)
     *   - file: voice or image (when message_type != text)
     *   - parent_message_id: optional (thread reply)
     *   - client_uuid: optional, for offline de-dup
     */
    public function store(SendMessageRequest $request, int $conversationId): JsonResponse
    {
        $user = $request->user();
        $conv = Conversation::findOrFail($conversationId);
        abort_unless($conv->participants->contains('user_id', $user->id), 403, 'Not a participant.');

        $message = DB::transaction(function () use ($request, $conv, $user) {
            $type = $request->input('message_type', 'text');
            $data = [
                'conversation_id' => $conv->id,
                'sender_id'       => $user->id,
                'parent_message_id' => $request->input('parent_message_id'),
                'client_uuid'     => $request->input('client_uuid'),
                'message_type'    => $type,
            ];
            if ($type === 'text') {
                $data['content_encrypted'] = $request->input('content');
            } else {
                $file = $request->file('file');
                $path = $file->store("messages/{$conv->id}", ['disk' => config('filesystems.private_disk', 'local')]);
                $data['media_path']  = $path;
                $data['media_size_bytes'] = $file->getSize();
                if ($type === 'voice') {
                    $data['media_duration_seconds'] = $request->input('duration_seconds');
                }
                $data['content_encrypted'] = $request->input('caption');   // optional caption
            }
            $msg = Message::create($data);
            $conv->update([
                'last_message_id'  => $msg->id,
                'last_message_at'  => $msg->created_at,
            ]);
            return $msg;
        });

        broadcast(new MessageSent($message));

        return response()->json((new MessageResource($message->load('sender')))->toArray($request), 201);
    }
}