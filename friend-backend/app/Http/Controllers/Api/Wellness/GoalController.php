<?php

namespace App\Http\Controllers\Api\Wellness;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\Wellness\StoreGoalRequest;
use App\Http\Requests\Api\Wellness\UpdateGoalRequest;
use App\Http\Resources\GoalResource;
use App\Models\Goal;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class GoalController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $page = Goal::where('user_id', $request->user()->id)
            ->orderByDesc('id')
            ->cursorPaginate((int) $request->query('per_page', 30));
        return response()->json([
            'data' => GoalResource::collection($page->items())->resolve($request),
            'next_cursor' => $page->nextCursor()?->encode(),
        ]);
    }

    public function store(StoreGoalRequest $request): JsonResponse
    {
        $goal = Goal::create(array_merge(
            ['user_id' => $request->user()->id, 'status' => 'active', 'progress' => 0],
            $request->validated()
        ));
        return response()->json((new GoalResource($goal))->toArray($request), 201);
    }

    public function update(UpdateGoalRequest $request, int $id): JsonResponse
    {
        $goal = Goal::where('user_id', $request->user()->id)->findOrFail($id);
        $goal->update($request->validated());
        return response()->json((new GoalResource($goal->fresh()))->toArray($request));
    }

    public function destroy(Request $request, int $id): JsonResponse
    {
        Goal::where('user_id', $request->user()->id)->findOrFail($id)->delete();
        return response()->json(['message' => 'Goal removed.']);
    }
}