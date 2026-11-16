<?php

namespace App\Http\Controllers\Api\Wellness;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\Wellness\StoreHabitRequest;
use App\Http\Requests\Api\Wellness\UpdateHabitRequest;
use App\Http\Resources\HabitResource;
use App\Models\Habit;
use App\Models\HabitLog;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class HabitController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $habits = Habit::where('user_id', $request->user()->id)
            ->where('is_archived', false)
            ->with(['logs' => fn ($q) => $q->orderByDesc('log_date')->limit(7)])
            ->orderBy('id')
            ->get();
        return response()->json(['data' => HabitResource::collection($habits)->resolve($request)]);
    }

    public function store(StoreHabitRequest $request): JsonResponse
    {
        $habit = Habit::create(array_merge(
            ['user_id' => $request->user()->id],
            $request->validated()
        ));
        return response()->json((new HabitResource($habit))->toArray($request), 201);
    }

    public function update(UpdateHabitRequest $request, int $id): JsonResponse
    {
        $habit = Habit::where('user_id', $request->user()->id)->findOrFail($id);
        $habit->update($request->validated());
        return response()->json((new HabitResource($habit->fresh()))->toArray($request));
    }

    public function destroy(Request $request, int $id): JsonResponse
    {
        Habit::where('user_id', $request->user()->id)->findOrFail($id)->delete();
        return response()->json(['message' => 'Habit archived.']);
    }

    /**
     * POST /api/habits/{id}/log
     * Body: { log_date: YYYY-MM-DD, completed: bool, note: string? }
     * Idempotent: same day = same row (handled by the unique index on
     * habit_id + log_date).
     */
    public function log(Request $request, int $id): JsonResponse
    {
        $habit = Habit::where('user_id', $request->user()->id)->findOrFail($id);
        $data = $request->validate([
            'log_date'  => ['required', 'date'],
            'completed' => ['nullable', 'boolean'],
            'note'      => ['nullable', 'string', 'max:500'],
        ]);

        $logDate = \Carbon\Carbon::parse($data['log_date'])->toDateString();
        $log = HabitLog::where('habit_id', $habit->id)->whereDate('log_date', $logDate)->first();
        if ($log) {
            $log->update([
                'completed' => $data['completed'] ?? true,
                'note'      => $data['note'] ?? $log->note,
            ]);
        } else {
            $log = HabitLog::create([
                'habit_id'  => $habit->id,
                'user_id'   => $request->user()->id,
                'log_date'  => $logDate,
                'completed' => $data['completed'] ?? true,
                'note'      => $data['note'] ?? null,
            ]);
        }
        return response()->json([
            'habit_id' => $habit->id,
            'log_date' => $log->log_date->toDateString(),
            'completed'=> $log->completed,
            'note'     => $log->note,
        ], 201);
    }
}