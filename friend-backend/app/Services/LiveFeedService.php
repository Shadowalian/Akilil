<?php

namespace App\Services;

use App\Events\LiveStreamActivity;
use App\Models\LiveStream;
use App\Models\LiveStreamEvent;
use App\Models\User;

/**
 * Writes the live-stream feed. Every item is stored (so a polling client
 * or a late joiner sees it) and broadcast (so a websocket client sees it
 * instantly). Presentation of an item lives here, in one place.
 */
class LiveFeedService
{
    public function comment(LiveStream $stream, User $user, string $body): LiveStreamEvent
    {
        return $this->push($stream, 'comment', $user, $body);
    }

    public function joined(LiveStream $stream, User $user): LiveStreamEvent
    {
        return $this->push($stream, 'join', $user);
    }

    public function like(LiveStream $stream, User $user, int $count): LiveStreamEvent
    {
        return $this->push($stream, 'like', $user, null, ['count' => $count]);
    }

    public function gift(LiveStream $stream, User $user, array $payload): LiveStreamEvent
    {
        return $this->push($stream, 'gift', $user, null, $payload);
    }

    /** Host / platform notices: started, ended, settings, viewer_removed. */
    public function system(LiveStream $stream, string $what, array $payload = []): LiveStreamEvent
    {
        return $this->push($stream, 'system', null, $what, $payload);
    }

    /** Keep the high-water mark of concurrent viewers. */
    public function touchPeak(LiveStream $stream): int
    {
        $now = $stream->currentViewerCount();
        if ($now > $stream->peak_viewers) {
            $stream->update(['peak_viewers' => $now]);
        }

        return $now;
    }

    public function present(LiveStreamEvent $e): array
    {
        return [
            'id'      => $e->id,
            'type'    => $e->type,
            'body'    => $e->body,
            'payload' => $e->payload ?? (object) [],
            'user'    => $e->user ? [
                'id'         => $e->user->id,
                'name'       => $e->user->name,
                'avatar_url' => $e->user->avatar_path,
            ] : null,
            'at'      => $e->created_at?->toIso8601String(),
        ];
    }

    private function push(LiveStream $stream, string $type, ?User $user, ?string $body = null, array $payload = []): LiveStreamEvent
    {
        $event = LiveStreamEvent::create([
            'live_stream_id' => $stream->id,
            'user_id' => $user?->id,
            'type'    => $type,
            'body'    => $body,
            'payload' => $payload ?: null,
        ]);
        $event->setRelation('user', $user);

        // A websocket outage must never fail a comment or (worse) a paid gift.
        try {
            broadcast(new LiveStreamActivity($stream->id, $this->present($event)));
        } catch (\Throwable $e) {
            report($e);
        }

        return $event;
    }
}
