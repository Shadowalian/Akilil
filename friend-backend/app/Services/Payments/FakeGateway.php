<?php

namespace App\Services\Payments;

use Illuminate\Support\Str;

/**
 * Test gateway. Used when STRIPE_SECRET is missing OR the env is
 * `local` / `testing` AND `FRIEND_PAYMENT_FAKE=1` (default in dev).
 *
 * The session URL points at our own `/api/wallet/topup/{reference}/confirm`
 * endpoint, which a dev can curl to simulate a webhook. Production
 * uses StripeGateway.
 */
class FakeGateway implements PaymentGateway
{
    public function createCheckoutSession(
        int $amountCents,
        string $currency,
        string $successUrl,
        string $cancelUrl,
        array $metadata = [],
    ): CheckoutSession {
        $reference = 'fake_' . Str::random(20);
        return new CheckoutSession(
            url: "/api/wallet/topup/{$reference}/confirm",
            reference: $reference,
            amountCents: $amountCents,
            currency: strtoupper($currency),
        );
    }

    public function parseWebhook(string $rawPayload, ?string $signatureHeader): ParsedEvent
    {
        $event = json_decode($rawPayload, true);
        if (! is_array($event)) {
            throw new GatewayException('Invalid fake payload');
        }
        return new ParsedEvent(
            type: $event['type'] ?? 'fake.completed',
            reference: $event['reference'] ?? '',
            amountCents: (int) ($event['amount_cents'] ?? 0),
            currency: strtoupper($event['currency'] ?? 'USD'),
            metadata: $event['metadata'] ?? [],
        );
    }

    public function refund(string $gatewayReference, int $amountCents): string
    {
        return 'fake_re_' . Str::random(16);
    }
}