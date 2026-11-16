<?php

namespace App\Http\Controllers\Api\Live;

use App\Http\Controllers\Controller;
use App\Http\Resources\LiveStreamResource;
use App\Models\LiveStream;
use App\Models\LiveStreamViewer;
use App\Models\User;
use App\Services\CookingRules;
use App\Services\JitsiService;
use App\Services\LiveFeedService;
use App\Support\AgeGate;
use Carbon\CarbonImmutable;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;

/**
 * Going live: a spiritual guide teaching or leading a reflection, a chef
 * cooking a recipe. One host on camera, an audience that watches,
 * comments, likes and sends gifts.
 *
 * Clinical psychiatry cannot broadcast — see config('akilil.live.pillars').
 */
class LiveStreamController extends Controller
{
    public function __construct(
        private JitsiService $jitsi,
        private CookingRules $cooking,
        private LiveFeedService $feed,
    ) {}

    /**
     * GET /api/live-streams?status=live|scheduled|ended&category=cooking&mine=1
     * Default: what is live now, then what is coming up.
     */
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        $q = LiveStream::query()->with(['professional', 'category', 'recipe']);

        if ($request->boolean('mine')) {
            $q->where('professional_user_id', $user->id);
            if ($status = $request->query('status')) {
                $q->where('status', $status);
            }
            $q->orderByDesc('scheduled_at');
        } else {
            $status = $request->query('status');
            $q->whereIn('status', $status ? [$status] : ['live', 'scheduled']);
            if (! $status || $status === 'scheduled') {
                // Hide broadcasts whose host never showed up.
                $q->where(fn ($w) => $w->where('status', '!=', 'scheduled')
                    ->orWhere('scheduled_at', '>=', now()->subHours(2)));
            }
            if ($slug = $request->query('category')) {
                $q->whereHas('category', fn ($c) => $c->where('slug', $slug));
            }
            if ($proId = $request->query('professional_user_id')) {
                $q->where('professional_user_id', (int) $proId);
            }
            // Live first, then soonest upcoming.
            $q->orderByRaw("CASE status WHEN 'live' THEN 0 WHEN 'scheduled' THEN 1 ELSE 2 END")
              ->orderBy('scheduled_at');
        }

        $page = $q->paginate((int) $request->query('per_page', 20));

        return response()->json([
            'data' => LiveStreamResource::collection($page->items())->resolve($request),
            'meta' => ['current_page' => $page->currentPage(), 'last_page' => $page->lastPage(), 'total' => $page->total()],
        ]);
    }

    /** GET /api/live-streams/{id} */
    public function show(Request $request, int $id): JsonResponse
    {
        $stream = LiveStream::with(['professional', 'category', 'recipe'])->findOrFail($id);

        return response()->json(['stream' => (new LiveStreamResource($stream))->toArray($request)]);
    }

    /**
     * POST /api/live-streams
     * Spiritual guides may go live now (omit scheduled_at) or announce a
     * time. Chefs must attach a recipe and announce ahead, so viewers who
     * want to cook along can shop first.
     */
    public function store(Request $request): JsonResponse
    {
        $host = $request->user();
        $profile = $host->professionalProfile()->with('category')->first();
        abort_unless($host->role === 'professional' && $profile, 403, 'Only professionals can go live.');
        abort_unless($profile->verification_status === 'approved', 403, 'Your profile must be verified before you can go live.');
        abort_unless(
            in_array($profile->category?->slug, config('akilil.live.pillars'), true),
            403,
            'Live broadcasts are available to spiritual guides and chefs. Clinical sessions stay private.'
        );

        $data = $request->validate([
            'title'          => ['required', 'string', 'min:3', 'max:160'],
            'description'    => ['nullable', 'string', 'max:5000'],
            'cover_image_path' => ['nullable', 'string', 'max:512'],
            'scheduled_at'   => ['nullable', 'date'],
            'recipe_id'      => ['nullable', 'integer'],
            'allow_comments' => ['nullable', 'boolean'],
            'allow_gifts'    => ['nullable', 'boolean'],
        ]);

        $startsAt = isset($data['scheduled_at'])
            ? CarbonImmutable::parse($data['scheduled_at'])->utc()
            : CarbonImmutable::now('UTC');
        if ($startsAt->lt(now()->subMinute())) {
            throw ValidationException::withMessages(['scheduled_at' => ['Pick a time in the future.']]);
        }

        $recipe = null;
        if ($profile->isCookingPillar()) {
            $recipe = $this->cooking->requireRecipe($host, $data['recipe_id'] ?? null);
            $this->cooking->requireLeadTime($startsAt);
        }

        $hasOpen = LiveStream::where('professional_user_id', $host->id)->where('status', 'live')->exists();
        abort_if($hasOpen, 422, 'You are already live. End that broadcast first.');

        $stream = LiveStream::create([
            'professional_user_id' => $host->id,
            'category_id'    => $profile->category_id,
            'recipe_id'      => $recipe?->id,
            'title'          => $data['title'],
            'description'    => $data['description'] ?? null,
            'cover_image_path' => $data['cover_image_path'] ?? null,
            'status'         => 'scheduled',
            'scheduled_at'   => $startsAt,
            'allow_comments' => $data['allow_comments'] ?? true,
            'allow_gifts'    => $data['allow_gifts'] ?? true,
        ]);

        return response()->json(['stream' => $this->present($stream, $request)], 201);
    }

    /** PUT /api/live-streams/{id} — host edits details / toggles comments & gifts. */
    public function update(Request $request, int $id): JsonResponse
    {
        $stream = $this->hosted($request, $id);
        abort_if(in_array($stream->status, ['ended', 'cancelled'], true), 422, 'This broadcast is over.');

        $data = $request->validate([
            'title'          => ['sometimes', 'string', 'min:3', 'max:160'],
            'description'    => ['sometimes', 'nullable', 'string', 'max:5000'],
            'cover_image_path' => ['sometimes', 'nullable', 'string', 'max:512'],
            'allow_comments' => ['sometimes', 'boolean'],
            'allow_gifts'    => ['sometimes', 'boolean'],
        ]);
        $stream->update($data);

        if ($stream->isLive()) {
            $this->feed->system($stream, 'settings', [
                'allow_comments' => $stream->allow_comments,
                'allow_gifts'    => $stream->allow_gifts,
            ]);
        }

        return response()->json(['stream' => $this->present($stream, $request)]);
    }

    /** POST /api/live-streams/{id}/start — the host goes on air. */
    public function start(Request $request, int $id): JsonResponse
    {
        $stream = $this->hosted($request, $id);
        abort_unless(in_array($stream->status, ['scheduled', 'live'], true), 422, 'This broadcast cannot be started.');

        if ($stream->status === 'scheduled') {
            if ($stream->recipe_id) {
                $this->cooking->requireNotTooEarly($stream->scheduled_at);
            }
            $stream->update([
                'status'     => 'live',
                'started_at' => now(),
                'room_name'  => $stream->room_name ?: $this->jitsi->newRoomName('live', $stream->id),
            ]);
            $this->feed->system($stream, 'started');
        }

        return response()->json([
            'session'      => $this->jitsi->sessionFor($request->user(), $stream->room_name, 'broadcast_host', true),
            'display_name' => $request->user()->name,
            'stream'       => $this->present($stream, $request),
        ]);
    }

    /** POST /api/live-streams/{id}/end */
    public function end(Request $request, int $id): JsonResponse
    {
        $stream = LiveStream::findOrFail($id);
        $user = $request->user();
        $isStaff = $user->hasAnyRole(['admin', 'moderator']);
        abort_unless($user->id === $stream->professional_user_id || $isStaff, 403, 'Only the host can end the broadcast.');

        if ($stream->status === 'live') {
            $stream->update(['status' => 'ended', 'ended_at' => now()]);
            $this->feed->system($stream, 'ended');
        } elseif ($stream->status === 'scheduled') {
            $stream->update(['status' => 'cancelled']);
        }

        return response()->json(['stream' => $this->present($stream, $request)]);
    }

    /**
     * POST /api/live-streams/{id}/join — a viewer starts watching.
     * Returns a receive-only room session plus the gift catalogue pointer.
     */
    public function join(Request $request, int $id): JsonResponse
    {
        $user = $request->user();
        $stream = LiveStream::findOrFail($id);

        if ($user->id === $stream->professional_user_id) {
            return $this->start($request, $id);
        }

        AgeGate::requireMinAge($user, (int) config('akilil.live.viewer_min_age'), 'watch live broadcasts');
        if (! $stream->isLive() || ! $stream->room_name) {
            throw ValidationException::withMessages([
                'status' => [$stream->status === 'scheduled' ? 'This broadcast has not started yet.' : 'This broadcast has ended.'],
            ]);
        }

        $viewer = LiveStreamViewer::firstOrNew(['live_stream_id' => $stream->id, 'user_id' => $user->id]);
        abort_if($viewer->is_banned, 403, 'The host removed you from this broadcast.');

        $firstJoin = ! $viewer->exists;
        $viewer->fill(['joined_at' => $viewer->joined_at ?? now(), 'last_seen_at' => now()])->save();

        if ($firstJoin) {
            $stream->increment('total_viewers');
            $this->feed->joined($stream, $user);
        }
        $this->feed->touchPeak($stream);

        return response()->json([
            'session'      => $this->jitsi->sessionFor($user, $stream->room_name, 'broadcast_view', false),
            'display_name' => $user->name,
            'stream'       => $this->present($stream, $request),
            'can_send_gifts' => $stream->allow_gifts && ! $user->isMinor() && $user->age() !== null,
        ]);
    }

    /** POST /api/live-streams/{id}/leave */
    public function leave(Request $request, int $id): JsonResponse
    {
        LiveStreamViewer::where('live_stream_id', $id)
            ->where('user_id', $request->user()->id)
            ->update(['last_seen_at' => now()->subMinutes(5)]);

        return response()->json(['message' => 'Left.']);
    }

    /** POST /api/live-streams/{id}/viewers/{userId}/ban — host removes a viewer. */
    public function ban(Request $request, int $id, int $userId): JsonResponse
    {
        $stream = $this->hosted($request, $id);
        abort_if($userId === $stream->professional_user_id, 422, 'You cannot remove yourself.');

        LiveStreamViewer::updateOrCreate(
            ['live_stream_id' => $stream->id, 'user_id' => $userId],
            ['is_banned' => true],
        );
        // Their earlier comments disappear for everyone.
        $stream->events()->where('user_id', $userId)->where('type', 'comment')->update(['removed_at' => now()]);
        $this->feed->system($stream, 'viewer_removed', ['user_id' => $userId]);

        return response()->json(['message' => 'Viewer removed.']);
    }

    /* ------------------------------------------------------------------ */

    private function hosted(Request $request, int $id): LiveStream
    {
        $stream = LiveStream::findOrFail($id);
        abort_unless($request->user()->id === $stream->professional_user_id, 403, 'Only the host can do this.');

        return $stream;
    }

    private function present(LiveStream $stream, Request $request): array
    {
        return (new LiveStreamResource($stream->fresh(['professional', 'category', 'recipe'])))->toArray($request);
    }
}
