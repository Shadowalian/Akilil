<?php

namespace App\Services\Payments;

/**
 * DTO returned from PaymentGateway::createCheckoutSession.
 * Akilil stores the reference so the webhook handler can
 * correlate the success event back to the right wallet.
 */
final class CheckoutSession
{
    public function __construct(
        public readonly string $url,
        public readonly string $reference,
        public readonly int $amountCents,
        public readonly string $currency,
    ) {}
}