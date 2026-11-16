<?php

namespace App\Events;

use App\Models\Message;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

/**
 * Broadcasts a single message to everyone in the conversation.
 *
 * Channel: private-conversation.{id}
 *   - private because the message body is sensitive
 *   - route is authorised in routes/channels.php (only participants
 *     can subscribe)
 *
 * ShouldBroadcastNow: realtime, no queue delay. The pusher protocol
 * pushes to all subscribers; if Reverb is down, the message is
 * delivered when the client reconnects via the REST history endpoint.
 */
class MessageSent implements ShouldBroadcastNow
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public function __construct(public Message $message) {}

    public function broadcastOn(): array
    {
        return [new PrivateChannel('conversation.' . $this->message->conversation_id)];
    }

    public function broadcastAs(): string
    {
        return 'message.sent';
    }

    public function broadcastWith(): array
    {
        $m = $this->message->loadMissing('sender');
        return [
            'id'              => $m->id,
            'conversation_id' => $m->conversation_id,
            'sender'          => $m->sender ? ['id'=>$m->sender->id,'name'=>$m->sender->name] : null,
            'message_type'    => $m->message_type,
            'media_path'      => $m->media_path,
            'media_duration_seconds' => $m->media_duration_seconds,
            'created_at'      => $m->created_at?->toIso8601String(),
            // Body is encrypted at rest; broadcast the cipher only to
            // authorised participants. Decryption happens on the
            // client after Reverb delivers.
            'body'            => $m->content_encrypted,
        ];
    }
}