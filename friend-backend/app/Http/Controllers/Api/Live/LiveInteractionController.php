<?php

namespace App\Http\Controllers\Api\Live;

use App\Http\Controllers\Controller;
use App\Jobs\ProcessContentForCrisisFlagsJob;
use App\Models\Gift;
use App\Models\GiftTransaction;
use App\Models\LiveStream;
use App\Models\LiveStreamEvent;
use App\Models\LiveStreamViewer;
use App\Models\User;
use App\Services\EarningsService;
use App\Services\LiveFeedService;
use App\Services\WalletService;
use App\Support\AgeGate;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\RateLimiter;

/**
 * What the audience does during a broadcast: read the feed, comment,
 * like, and send gifts.
 */
class LiveInteractionController extends Controller
{
    public function __construct(
        private LiveFeedService $feed,
        private WalletService $wallet,
        private EarningsService $earnings,
    ) {}

    /**
     * GET /api/live-streams/{id}/events?after={lastEventId}
     * The feed since a cursor, plus current room state. Calling this is
     * also the viewer's heartbeat — it is what keeps them in the count.
     */
    public function events(Request $request, int $id): JsonResponse
    {
        $user = $request->user();
        $stream = LiveStream::findOrFail($id);
        $after = (int) $request->query('after', 0);

        $isHost = $user->id === $stream->professional_user_id;
        if (! $isHost && $stream->isLive()) {
            $viewer = LiveStreamViewer::where('live_stream_id', $stream->id)->where('user_id', $user->id)->first();
            if ($viewer?->is_banned) {
                return response()->json(['code' => 'removed', 'message' => 'The host removed you from this broadcast.'], 403);
            }
            $viewer?->update(['last_seen_at' => now()]);
        }

        $q = LiveStreamEvent::with('user')
            ->where('live_stream_id', $stream->id)
            ->whereNull('removed_at');

        // First call (no cursor): just the recent tail, not the whole history.
        $events = $after > 0
            ? $q->where('id', '>', $after)->orderBy('id')->limit(100)->get()
            : $q->orderByDesc('id')->limit(30)->get()->reverse()->values();

        return response()->json([
            'events' => $events->map(fn ($e) => $this->feed->present($e))->values(),
            'cursor' => $events->last()?->id ?? $after,
            // Ids removed by the host since the cursor, so clients can drop them.
            'removed_ids' => $after > 0
                ? LiveStreamEvent::where('live_stream_id', $stream->id)
                    ->where('removed_at', '>=', now()->subMinutes(2))->pluck('id')
                : [],
            'state' => [
                'status'         => $stream->status,
                'viewer_count'   => $stream->isLive() ? $this->feed->touchPeak($stream) : 0,
                'likes_count'    => $stream->likes_count,
                'allow_comments' => (bool) $stream->allow_comments,
                'allow_gifts'    => (bool) $stream->allow_gifts,
                'gifts_total_cents' => $isHost ? $stream->gifts_total_cents : null,
            ],
        ]);
    }

    /** POST /api/live-streams/{id}/comments  { body } */
    public function comment(Request $request, int $id): JsonResponse
    {
        $user = $request->user();
        $stream = $this->liveFor($user, $id);
        abort_unless($stream->allow_comments, 422, 'The host has turned comments off.');

        $data = $request->validate([
            'body' => ['required', 'string', 'min:1', 'max:'.(int) config('akilil.live.max_comment_length')],
        ]);

        $key = "live-comment:{$stream->id}:{$user->id}";
        if (RateLimiter::tooManyAttempts($key, (int) config('akilil.live.comments_per_minute'))) {
            return response()->json(['message' => 'You are commenting too fast. Take a breath.', 'code' => 'slow_down'], 429);
        }
        RateLimiter::hit($key, 60);

        $event = $this->feed->comment($stream, $user, trim($data['body']));

        // Someone may reach out for help in a public chat. Same human-review
        // pipeline as journals, vents and messages.
        ProcessContentForCrisisFlagsJob::dispatch('live_comment', $event->id, (string) $event->body, $user->id);

        return response()->json(['event' => $this->feed->present($event)], 201);
    }

    /** POST /api/live-streams/{id}/likes  { count? }  — taps are batched client-side. */
    public function like(Request $request, int $id): JsonResponse
    {
        $user = $request->user();
        $stream = $this->liveFor($user, $id);
        $count = max(1, min((int) $request->input('count', 1), 50));

        $key = "live-like:{$stream->id}:{$user->id}";
        if (RateLimiter::tooManyAttempts($key, 30)) {
            return response()->json(['likes_count' => $stream->likes_count]);
        }
        RateLimiter::hit($key, 60);

        $stream->increment('likes_count', $count);
        $this->feed->like($stream, $user, $count);

        return response()->json(['likes_count' => $stream->fresh()->likes_count]);
    }

    /**
     * POST /api/live-streams/{id}/gifts  { gift_id | gift_slug, quantity? }
     * Debits the sender's wallet, credits the host's earnings (net of the
     * platform fee) and drops the gift into the feed — all or nothing.
     */
    public function gift(Request $request, int $id): JsonResponse
    {
        $sender = $request->user();
        $stream = $this->liveFor($sender, $id);
        abort_unless($stream->allow_gifts, 422, 'The host has turned gifts off.');
        abort_if($sender->id === $stream->professional_user_id, 422, 'You cannot send yourself a gift.');
        // Gifts are real money: known-age adults only.
        AgeGate::requireAdultPayer($sender);
        AgeGate::requireMinAge($sender, (int) config('akilil.gifts.min_age'), 'send gifts');

        $data = $request->validate([
            'gift_id'   => ['required_without:gift_slug', 'integer'],
            'gift_slug' => ['required_without:gift_id', 'string'],
            'quantity'  => ['nullable', 'integer', 'min:1', 'max:'.(int) config('akilil.gifts.max_quantity')],
        ]);
        $gift = Gift::where('is_active', true)
            ->when(isset($data['gift_id']), fn ($q) => $q->whereKey($data['gift_id']), fn ($q) => $q->where('slug', $data['gift_slug']))
            ->first();
        abort_unless($gift, 422, 'That gift is not available.');

        $quantity = (int) ($data['quantity'] ?? 1);
        $total    = $gift->price_cents * $quantity;
        $currency = config('akilil.currency');

        if (! $this->wallet->canAfford($sender, $total, $currency)) {
            return response()->json([
                'message'        => 'Top up your wallet to send this gift.',
                'code'           => 'insufficient_balance',
                'required_cents' => $total,
                'balance_cents'  => $this->wallet->walletFor($sender)->balance_cents,
                'currency'       => $currency,
            ], 402);
        }

        $host = User::findOrFail($stream->professional_user_id);

        [$giftTx, $event] = DB::transaction(function () use ($sender, $host, $stream, $gift, $quantity, $total, $currency) {
            $giftTx = GiftTransaction::create([
                'gift_id'           => $gift->id,
                'live_stream_id'    => $stream->id,
                'sender_user_id'    => $sender->id,
                'recipient_user_id' => $host->id,
                'quantity'          => $quantity,
                'unit_price_cents'  => $gift->price_cents,
                'total_cents'       => $total,
                'currency'          => $currency,
            ]);
            $tx = $this->wallet->debit($sender, $total, $currency, 'gift', $giftTx);
            $giftTx->update(['transaction_id' => $tx->id]);

            $this->earnings->record($host, 'gift', $total, $giftTx, $currency);
            $stream->increment('gifts_total_cents', $total);

            $event = $this->feed->gift($stream, $sender, [
                'gift' => [
                    'id'        => $gift->id,
                    'slug'      => $gift->slug,
                    'name'      => $gift->name,
                    'emoji'     => $gift->emoji,
                    'animation' => $gift->animation,
                ],
                'quantity' => $quantity,
            ]);

            return [$giftTx, $event];
        });

        return response()->json([
            'event'         => $this->feed->present($event),
            'spent_cents'   => $giftTx->total_cents,
            'balance_cents' => $this->wallet->walletFor($sender)->balance_cents,
            'currency'      => $currency,
        ], 201);
    }

    /** DELETE /api/live-stream-events/{id} — the host (or a moderator) removes a comment. */
    public function removeEvent(Request $request, int $id): JsonResponse
    {
        $event = LiveStreamEvent::with('stream')->findOrFail($id);
        $user = $request->user();
        abort_unless(
            $user->id === $event->stream->professional_user_id || $user->hasAnyRole(['admin', 'moderator']),
            403,
            'Only the host can remove comments.'
        );
        abort_unless($event->type === 'comment', 422, 'Only comments can be removed.');
        $event->update(['removed_at' => now()]);

        return response()->json(['message' => 'Removed.']);
    }

    /** GET /api/gifts — the catalogue shown in the gift tray. */
    public function catalogue(): JsonResponse
    {
        return response()->json([
            'currency' => config('akilil.currency'),
            'min_age'  => (int) config('akilil.gifts.min_age'),
            'data'     => Gift::where('is_active', true)->orderBy('sort_order')->orderBy('price_cents')->get()
                ->map(fn ($g) => [
                    'id'          => $g->id,
                    'slug'        => $g->slug,
                    'name'        => $g->name,
                    'emoji'       => $g->emoji,
                    'price_cents' => $g->price_cents,
                    'animation'   => $g->animation,
                ]),
        ]);
    }

    /** A live stream this user may interact with (host, or a non-banned viewer). */
    private function liveFor(User $user, int $id): LiveStream
    {
        $stream = LiveStream::findOrFail($id);
        abort_unless($stream->isLive(), 422, 'This broadcast is not live.');

        if ($user->id !== $stream->professional_user_id) {
            $viewer = LiveStreamViewer::where('live_stream_id', $stream->id)->where('user_id', $user->id)->first();
            abort_unless($viewer, 403, 'Join the broadcast first.');
            abort_if($viewer->is_banned, 403, 'The host removed you from this broadcast.');
        }

        return $stream;
    }
}
