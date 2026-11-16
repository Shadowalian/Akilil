<?php

namespace App\Http\Controllers\Api\Webhook;

use App\Http\Controllers\Controller;
use App\Services\Payments\GatewayException;
use App\Services\Payments\PaymentGateway;
use App\Services\WalletService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

/**
 * POST /api/webhooks/stripe — Stripe pushes events here.
 *
 * We do NOT trust the request body directly: the gateway's
 * parseWebhook() verifies the HMAC signature and throws
 * GatewayException on any mismatch. The handler is idempotent —
 * if the same event arrives twice, the WalletService
 * `completeTopup` short-circuits because the transaction is
 * already `succeeded`.
 */
class StripeWebhookController extends Controller
{
    public function __construct(
        private readonly PaymentGateway $gateway,
        private readonly WalletService  $wallets,
    ) {}

    public function handle(Request $request): JsonResponse
    {
        try {
            $event = $this->gateway->parseWebhook(
                $request->getContent(),
                $request->header('Stripe-Signature'),
            );
        } catch (GatewayException $e) {
            Log::warning('Stripe webhook signature failed', ['error' => $e->getMessage()]);
            return response()->json(['error' => 'invalid signature'], 400);
        }

        match ($event->type) {
            'checkout.session.completed' => $this->wallets->completeTopup(
                $event->reference,
                $event->metadata,
            ),
            'charge.refunded' => Log::info('Stripe refund event', [
                'reference' => $event->refundedReference,
            ]),
            default => Log::info('Unhandled Stripe event', ['type' => $event->type]),
        };

        return response()->json(['received' => true]);
    }
}