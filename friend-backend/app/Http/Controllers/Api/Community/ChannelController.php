<?php

namespace App\Http\Controllers\Api\Community;

use App\Http\Controllers\Controller;
use App\Http\Resources\CommunityChannelResource;
use App\Models\CommunityChannel;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ChannelController extends Controller
{
    /**
     * GET /api/community/channels
     * Every non-archived channel, alphabetical. Empty list when nothing has
     * been created yet — channels are seeded/administered, never created
     * implicitly by a request.
     */
    public function index(Request $request): JsonResponse
    {
        $channels = CommunityChannel::where('is_archived', false)
            ->orderBy('name')
            ->get();

        return response()->json([
            'data' => CommunityChannelResource::collection($channels)->resolve($request),
        ]);
    }

    /**
     * GET /api/community/channels/{id}
     * Opening a channel joins the caller — the feed itself is the join
     * gesture, so there is no separate join endpoint.
     */
    public function show(Request $request, int $id): JsonResponse
    {
        $channel = CommunityChannel::where('is_archived', false)->findOrFail($id);
        $channel->joinMember($request->user()->id);

        return response()->json(
            (new CommunityChannelResource($channel->fresh()))->toArray($request)
        );
    }
}
