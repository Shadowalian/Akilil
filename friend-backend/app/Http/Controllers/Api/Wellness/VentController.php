<?php

namespace App\Http\Controllers\Api\Wellness;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\Wellness\StoreVentRequest;
use App\Http\Resources\VentResource;
use App\Models\Vent;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class VentController extends Controller
{
    /**
     * POST /api/vents
     * Multipart. Either text (content) OR voice (file), is_anonymous flag,
     * optional expires_at for "disappearing" vents.
     */
    public function store(StoreVentRequest $request): JsonResponse
    {
        $user = $request->user();
        $type = $request->input('content_type', 'text');
        $data = [
            'author_user_id' => $user->id,
            'content_type'   => $type,
            'is_anonymous'   => (bool) $request->input('is_anonymous', false),
            'expires_at'     => $request->input('expires_at'),
        ];

        if ($type === 'voice') {
            $file = $request->file('file');
            $path = $file->store("vents/{$user->id}", ['disk' => config('filesystems.private_disk', 'local')]);
            $data['voice_path'] = $path;
            $data['voice_duration_seconds'] = $request->input('duration_seconds');
        } else {
            $data['content'] = $request->input('content');
        }

        $vent = Vent::create($data);
        return response()->json((new VentResource($vent))->toArray($request), 201);
    }

    /**
     * GET /api/vents
     * Returns the user's own vents (including anonymous ones).
     * Anonymous venting from other users is intentionally not exposed.
     */
    public function index(Request $request): JsonResponse
    {
        $page = Vent::where('author_user_id', $request->user()->id)
            ->where(function ($q) {
                $q->whereNull('expires_at')->orWhere('expires_at', '>', now());
            })
            ->orderByDesc('id')
            ->cursorPaginate((int) $request->query('per_page', 30));
        return response()->json([
            'data' => VentResource::collection($page->items())->resolve($request),
            'next_cursor' => $page->nextCursor()?->encode(),
        ]);
    }

    public function destroy(Request $request, int $id): JsonResponse
    {
        $vent = Vent::where('id', $id)->where('author_user_id', $request->user()->id)->firstOrFail();
        $vent->delete();
        if ($vent->voice_path) {
            Storage::disk(config('filesystems.private_disk', 'local'))->delete($vent->voice_path);
        }
        return response()->json(['message' => 'Vent removed.']);
    }
}