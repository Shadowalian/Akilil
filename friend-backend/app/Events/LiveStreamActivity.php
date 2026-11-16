<?php

namespace App\Events;

use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Foundation\Events\Dispatchable;

/**
 * Pushes one feed item (comment, gift, like, state change) to everyone
 * watching a live stream over Reverb. The same items are available from
 * GET /live-streams/{id}/events, which clients poll as a fallback.
 *
 * Public channel on purpose: the payload is exactly what any signed-in
 * viewer can already read, and a public channel skips a per-viewer auth
 * round-trip when thousands join at once.
 */
class LiveStreamActivity implements ShouldBroadcastNow
{
    use Dispatchable, InteractsWithSockets;

    public function __construct(public int $liveStreamId, public array $item) {}

    public function broadcastOn(): array
    {
        return [new Channel('live-stream.'.$this->liveStreamId)];
    }

    public function broadcastAs(): string
    {
        return 'live.activity';
    }

    public function broadcastWith(): array
    {
        return $this->item;
    }
}
