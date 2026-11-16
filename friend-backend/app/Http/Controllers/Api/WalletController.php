<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Transaction;
use App\Services\WalletService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class WalletController extends Controller
{
    public function __construct(private readonly WalletService $wallets) {}

    /** GET /api/me/wallet — current balance + lifetime totals. */
    public function show(Request $request): JsonResponse
    {
        $user = $request->user();
        $wallet = $this->wallets->walletFor($user);
        return response()->json([
            'currency' => $wallet->currency,
            'balance_cents'        => $wallet->balance_cents,
            'pending_cents'        => $wallet->pending_cents,
            'lifetime_topup_cents' => $wallet->lifetime_topup_cents,
            'lifetime_spent_cents' => $wallet->lifetime_spent_cents,
        ]);
    }

    /** GET /api/me/wallet/transactions — paginated ledger. */
    public function transactions(Request $request): JsonResponse
    {
        $user = $request->user();
        $list = Transaction::where('user_id', $user->id)
            ->orderBy('created_at', 'desc')
            ->limit(50)
            ->get();
        return response()->json(['data' => $list]);
    }

    /**
     * POST /api/wallet/topup — start a top-up.
     * Returns { url, transaction_id }.
     */
    public function topup(Request $request): JsonResponse
    {
        // Minors never pay: their guardian tops up and books.
        \App\Support\AgeGate::requireAdultPayer($request->user());

        $data = $request->validate([
            'amount_cents' => ['required', 'integer', 'min:100', 'max:10000000'],
            'currency'     => ['sometimes', 'string', Rule::in(['USD', 'ETB', 'EUR', 'GBP'])],
        ]);
        $result = $this->wallets->beginTopup(
            user: $request->user(),
            amountCents: $data['amount_cents'],
            currency: $this->wallets->walletFor($request->user())->currency,
        );
        return response()->json([
            'checkout_url'   => $result['session']->url,
            'transaction_id' => $result['transaction']->id,
            'reference'      => $result['session']->reference,
        ], 201);
    }

    /**
     * POST /api/wallet/topup/{reference}/confirm — DEV ONLY.
     * When the fake gateway is in use, this is the URL the user
     * gets redirected to. Hitting it simulates a successful
     * checkout.session.completed webhook. Hidden behind
     * `app.debug` so it never appears in production.
     */
    public function fakeConfirm(Request $request, string $reference): JsonResponse
    {
        if (! config('app.debug')) {
            abort(404);
        }
        $tx = $this->wallets->completeTopup($reference, [
            'source' => 'fake_confirm_endpoint',
        ]);
        return response()->json([
            'status'   => $tx->status,
            'tx_id'    => $tx->id,
        ]);
    }
}