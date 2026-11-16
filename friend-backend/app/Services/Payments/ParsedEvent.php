<?php

namespace App\Services\Payments;

/**
 * DTO returned from PaymentGateway::parseWebhook — a normalized
 * event shape regardless of provider. The webhook controller maps
 * these to local transactions / wallet updates.
 */
final class ParsedEvent
{
    public function __construct(
        public readonly string $type,        // 'checkout.session.completed', 'charge.refunded', etc.
        public readonly string $reference,   // gateway's session/charge id
        public readonly int    $amountCents,
        public readonly string $currency,
        public readonly array  $metadata,    // provider metadata + ours
        public readonly ?string $refundedReference = null,
    ) {}
}