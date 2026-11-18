<?php

namespace App\Services\Payments;

/**
 * Used in production when no real payment provider is configured.
 *
 * Fails closed: every operation refuses with a clear message, so money can
 * never move through the test gateway by accident.
 */
class UnconfiguredGateway implements PaymentGateway
{
    private const MESSAGE = 'Payments are not set up yet. Please try again later.';

    public function createCheckoutSession(
        int $amountCents,
        string $currency,
        string $successUrl,
        string $cancelUrl,
        array $metadata = [],
    ): CheckoutSession {
        throw new GatewayException(self::MESSAGE);
    }

    public function parseWebhook(string $rawPayload, ?string $signatureHeader): ParsedEvent
    {
        throw new GatewayException(self::MESSAGE);
    }

    public function refund(string $gatewayReference, int $amountCents): string
    {
        throw new GatewayException(self::MESSAGE);
    }
}
