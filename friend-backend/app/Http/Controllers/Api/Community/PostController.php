<?php

namespace App\Http\Controllers\Api\Community;

use App\Events\CommunityPostCreated;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\Community\StorePostRequest;
use App\Http\Resources\CommunityPostResource;
use App\Models\CommunityChannel;
use App\Models\CommunityPost;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class PostController extends Controller
{
    /**
     * GET /api/community/channels/{id}/posts
     * Channel feed, newest first. Hidden/removed posts and threaded replies
     * stay out of the feed.
     */
    public function index(Request $request, int $channelId): JsonResponse
    {
        $channel = CommunityChannel::findOrFail($channelId);

        $page = CommunityPost::where('channel_id', $channel->id)
            ->where('moderation_status', 'visible')
            ->whereNull('parent_post_id')
            ->with('author')
            ->orderByDesc('created_at')
            ->orderByDesc('id')
            ->paginate((int) $request->query('per_page', 20));

        return response()->json([
            'data' => CommunityPostResource::collection($page->items())->resolve($request),
            'meta' => [
                'current_page' => $page->currentPage(),
                'last_page'    => $page->lastPage(),
                'per_page'     => $page->perPage(),
                'total'        => $page->total(),
            ],
        ]);
    }

    /**
     * POST /api/community/channels/{id}/posts
     * Posting joins the channel if the author is not a member yet.
     * client_uuid makes offline-composed posts idempotent on retry: an
     * existing row is returned (200) instead of a duplicate (201).
     */
    public function store(StorePostRequest $request, int $channelId): JsonResponse
    {
        $user    = $request->user();
        $channel = CommunityChannel::where('is_archived', false)->findOrFail($channelId);
        $data    = $request->validated();

        if (! empty($data['client_uuid'])) {
            $existing = CommunityPost::where('client_uuid', $data['client_uuid'])->first();
            if ($existing) {
                return response()->json(
                    (new CommunityPostResource($existing->load('author')))->toArray($request), 200
                );
            }
        }

        $post = DB::transaction(function () use ($channel, $user, $data) {
            $channel->joinMember($user->id);

            return CommunityPost::create([
                'channel_id'  => $channel->id,
                'author_id'   => $user->id,
                'client_uuid' => $data['client_uuid'] ?? null,
                'content'     => $data['content'],
            ]);
        });

        broadcast(new CommunityPostCreated($post));

        return response()->json(
            (new CommunityPostResource($post->load('author')))->toArray($request), 201
        );
    }
}
