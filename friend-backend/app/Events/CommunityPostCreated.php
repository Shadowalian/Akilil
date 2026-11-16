<?php

namespace App\Events;

use App\Models\CommunityPost;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PresenceChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

/**
 * Broadcasts a new community post to a channel-scoped presence channel.
 * PresenceChannel lets the client show "who's in the channel" UI.
 */
class CommunityPostCreated implements ShouldBroadcastNow
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public function __construct(public CommunityPost $post) {}

    public function broadcastOn(): array
    {
        return [new PresenceChannel('channel.' . $this->post->channel_id)];
    }

    public function broadcastAs(): string
    {
        return 'post.created';
    }

    public function broadcastWith(): array
    {
        $p = $this->post->loadMissing('author');
        return [
            'id'         => $p->id,
            'channel_id' => $p->channel_id,
            'author'     => $p->author ? ['id'=>$p->author->id,'name'=>$p->author->name] : null,
            'content'    => $p->content,
            'created_at' => $p->created_at?->toIso8601String(),
        ];
    }
}