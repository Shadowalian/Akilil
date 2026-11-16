<?php

namespace App\Http\Controllers\Api\Professional;

use App\Http\Controllers\Controller;
use App\Http\Resources\AppointmentResource;
use App\Models\Appointment;
use Carbon\CarbonImmutable;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ProAppointmentController extends Controller
{
    /**
     * GET /api/professional/appointments
     * The pro-side agenda: only sessions where the caller is the professional.
     */
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        abort_unless($user->role === 'professional', 403, 'Only professionals can view this.');

        $q = Appointment::query()
            ->where('professional_user_id', $user->id)
            ->with('client')
            ->orderByDesc('scheduled_at');

        if ($status = $request->query('status')) {
            $q->where('status', $status);
        }
        if ($after = $request->query('starts_after')) {
            $q->where('scheduled_at', '>=', CarbonImmutable::parse($after));
        }
        if ($before = $request->query('ends_before')) {
            $q->where('scheduled_at', '<=', CarbonImmutable::parse($before));
        }

        $page = $q->paginate((int) $request->query('per_page', 20));

        return response()->json([
            'data' => AppointmentResource::collection($page->items())->resolve($request),
            'meta' => [
                'current_page' => $page->currentPage(),
                'last_page'    => $page->lastPage(),
                'per_page'     => $page->perPage(),
                'total'        => $page->total(),
            ],
        ]);
    }
}
