<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\NotificationResource;
use App\Models\User;
use App\Models\UserNotification;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class NotificationController extends Controller
{
    /**
     * GET /api/notifications
     * The caller's notification centre, newest first.
     */
    public function index(Request $request): JsonResponse
    {
        $page = $this->forUser($request->user())
            ->orderByDesc('created_at')
            ->paginate((int) $request->query('per_page', 20));

        return response()->json([
            'data' => NotificationResource::collection($page->items())->resolve($request),
            'meta' => [
                'current_page' => $page->currentPage(),
                'last_page'    => $page->lastPage(),
                'per_page'     => $page->perPage(),
                'total'        => $page->total(),
            ],
        ]);
    }

    /**
     * POST /api/notifications/{id}/read
     * Idempotent: re-reading keeps the original read_at.
     */
    public function markRead(Request $request, string $id): JsonResponse
    {
        $notification = $this->forUser($request->user())->findOrFail($id);

        if (! $notification->read_at) {
            $notification->update(['read_at' => now()]);
        }

        return response()->json((new NotificationResource($notification))->toArray($request));
    }

    /** POST /api/notifications/read-all */
    public function markAllRead(Request $request): JsonResponse
    {
        $updated = $this->forUser($request->user())->whereNull('read_at')->update(['read_at' => now()]);

        return response()->json(['updated' => $updated]);
    }

    /**
     * GET /api/notifications/unread-count
     */
    public function unreadCount(Request $request): JsonResponse
    {
        return response()->json([
            'unread_count' => $this->forUser($request->user())->whereNull('read_at')->count(),
        ]);
    }

    /**
     * `notifications` is Laravel's polymorphic notification table, so the
     * recipient is matched on the morph pair rather than a user_id column.
     */
    private function forUser(User $user): Builder
    {
        return UserNotification::query()
            ->where('notifiable_type', User::class)
            ->where('notifiable_id', $user->id);
    }
}
