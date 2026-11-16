<?php

namespace App\Http\Controllers\Api\Professional;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\Professional\StorePayoutRequest;
use App\Http\Resources\PayoutResource;
use App\Models\Payout;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PayoutController extends Controller
{
    /**
     * GET /api/professional/payouts
     */
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        abort_unless($user->role === 'professional', 403, 'Only professionals can view payouts.');

        $page = Payout::where('professional_user_id', $user->id)
            ->orderByDesc('scheduled_for')
            ->orderByDesc('id')
            ->paginate((int) $request->query('per_page', 20));

        return response()->json([
            'data' => PayoutResource::collection($page->items())->resolve($request),
            'meta' => [
                'current_page' => $page->currentPage(),
                'last_page'    => $page->lastPage(),
                'per_page'     => $page->perPage(),
                'total'        => $page->total(),
            ],
        ]);
    }

    /**
     * POST /api/professional/payouts
     * Requests a payout. It lands as 'scheduled'; Task 9's disbursement run
     * moves it through processing → succeeded/failed.
     */
    public function store(StorePayoutRequest $request): JsonResponse
    {
        $user = $request->user();
        abort_unless($user->role === 'professional', 403, 'Only professionals can request payouts.');

        $payout = Payout::create([
            'professional_user_id' => $user->id,
            'amount_cents'         => (int) $request->input('amount_cents'),
            'currency'             => $user->professionalProfile?->currency ?: 'USD',
            'platform_fee_cents'   => 0,
            'status'               => 'scheduled',
            'gateway'              => null,
            'scheduled_for'        => now()->toDateString(),
        ]);

        return (new PayoutResource($payout))->response()->setStatusCode(201);
    }
}
