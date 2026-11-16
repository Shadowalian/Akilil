<?php

namespace App\Http\Controllers\Api\Wellness;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\Wellness\StoreJournalEntryRequest;
use App\Http\Requests\Api\Wellness\UpdateJournalEntryRequest;
use App\Http\Resources\JournalEntryResource;
use App\Models\JournalEntry;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class JournalController extends Controller
{
    /**
     * GET /api/journal-entries
     * Cursor pagination by created_at desc. Returns user's own only.
     */
    public function index(Request $request): JsonResponse
    {
        $page = JournalEntry::where('user_id', $request->user()->id)
            ->orderByDesc('id')
            ->cursorPaginate((int) $request->query('per_page', 30));

        return response()->json([
            'data' => JournalEntryResource::collection($page->items())->resolve($request),
            'next_cursor' => $page->nextCursor()?->encode(),
        ]);
    }

    public function show(Request $request, int $id): JsonResponse
    {
        $entry = JournalEntry::where('user_id', $request->user()->id)->findOrFail($id);
        return response()->json((new JournalEntryResource($entry))->toArray($request));
    }

    /**
     * POST /api/journal-entries
     * Supports offline-created entries via client_uuid (idempotent on retry):
     * if a row already exists with that uuid, return it (200) instead of
     * creating a duplicate (201).
     */
    public function store(StoreJournalEntryRequest $request): JsonResponse
    {
        $user = $request->user();
        $data = $request->validated();

        if (! empty($data['client_uuid'])) {
            $existing = JournalEntry::where('user_id', $user->id)
                ->where('client_uuid', $data['client_uuid'])
                ->first();
            if ($existing) {
                return response()->json((new JournalEntryResource($existing))->toArray($request), 200);
            }
        }

        $entry = JournalEntry::create(array_merge(
            ['user_id' => $user->id, 'is_private' => true],
            $data,
        ));
        return response()->json((new JournalEntryResource($entry))->toArray($request), 201);
    }

    public function update(UpdateJournalEntryRequest $request, int $id): JsonResponse
    {
        $entry = JournalEntry::where('user_id', $request->user()->id)->findOrFail($id);
        $entry->update($request->validated());
        return response()->json((new JournalEntryResource($entry->fresh()))->toArray($request));
    }

    public function destroy(Request $request, int $id): JsonResponse
    {
        $entry = JournalEntry::where('user_id', $request->user()->id)->findOrFail($id);
        $entry->delete();
        return response()->json(['message' => 'Entry deleted.']);
    }
}