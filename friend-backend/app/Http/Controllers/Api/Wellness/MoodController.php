<?php

namespace App\Http\Controllers\Api\Wellness;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\Wellness\StoreMoodLogRequest;
use App\Http\Resources\MoodLogResource;
use App\Models\MoodLog;
use Carbon\CarbonImmutable;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class MoodController extends Controller
{
    /**
     * POST /api/mood-logs
     */
    public function store(StoreMoodLogRequest $request): JsonResponse
    {
        $user = $request->user();
        $log = MoodLog::create(array_merge(
            ['user_id' => $user->id, 'logged_at' => $request->input('logged_at', now())],
            $request->validated()
        ));
        return response()->json((new MoodLogResource($log))->toArray($request), 201);
    }

    public function index(Request $request): JsonResponse
    {
        $page = MoodLog::where('user_id', $request->user()->id)
            ->orderByDesc('logged_at')
            ->cursorPaginate((int) $request->query('per_page', 60));
        return response()->json([
            'data' => MoodLogResource::collection($page->items())->resolve($request),
            'next_cursor' => $page->nextCursor()?->encode(),
        ]);
    }

    /**
     * GET /api/mood-logs/analytics?group_by=day|week|month&from=&to=
     * Returns average mood score per bucket — feeds the Flutter chart.
     */
    public function analytics(Request $request): JsonResponse
    {
        $request->validate([
            'group_by' => ['required', 'in:day,week,month'],
            'from'     => ['nullable', 'date'],
            'to'       => ['nullable', 'date', 'after_or_equal:from'],
        ]);

        $userId = $request->user()->id;
        $groupBy = $request->input('group_by', 'day');
        $from    = $request->input('from') ? CarbonImmutable::parse($request->input('from')) : CarbonImmutable::now()->subMonths(3);
        $to      = $request->input('to')   ? CarbonImmutable::parse($request->input('to'))   : CarbonImmutable::now();

        // MySQL DATE_FORMAT works for day/week; for week we use YEARWEEK.
        $bucket = match ($groupBy) {
            'day'   => "DATE(logged_at)",
            'week'  => "CONCAT(YEAR(logged_at), '-W', LPAD(WEEK(logged_at, 3), 2, '0'))",
            'month' => "DATE_FORMAT(logged_at, '%Y-%m')",
        };

        $rows = DB::table('mood_logs')
            ->selectRaw("$bucket AS bucket, AVG(mood_score) AS avg_score, COUNT(*) AS samples")
            ->where('user_id', $userId)
            ->whereBetween('logged_at', [$from, $to])
            ->groupBy('bucket')
            ->orderBy('bucket')
            ->get();

        return response()->json([
            'group_by' => $groupBy,
            'from'     => $from->toDateString(),
            'to'       => $to->toDateString(),
            'series'   => $rows->map(fn ($r) => [
                'bucket'     => $r->bucket,
                'avg_score'  => round((float) $r->avg_score, 2),
                'samples'    => (int) $r->samples,
            ]),
        ]);
    }
}