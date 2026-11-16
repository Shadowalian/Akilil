<?php

namespace App\Http\Controllers\Api\Community;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\Community\StoreReportRequest;
use App\Models\CommunityPost;
use Illuminate\Http\JsonResponse;

class ReportController extends Controller
{
    /**
     * POST /api/community/posts/{id}/report
     * Flags a post for the admin moderation queue. Reporting does not hide
     * the post — a moderator decides that.
     */
    public function store(StoreReportRequest $request, int $postId): JsonResponse
    {
        $post = CommunityPost::findOrFail($postId);
        $data = $request->validated();

        $report = $post->reports()->create([
            'reporter_id' => $request->user()->id,
            'reason'      => $data['reason'],
            'description' => $data['description'] ?? null,
        ])->fresh();

        return response()->json([
            'id'         => $report->id,
            'post_id'    => $post->id,
            'reason'     => $report->reason,
            'status'     => $report->status,
            'created_at' => optional($report->created_at)?->toIso8601String(),
        ], 201);
    }
}
