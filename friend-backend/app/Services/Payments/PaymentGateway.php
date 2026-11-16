<?php

namespace App\Services\Payments;

/**
 * Payment-gateway contract. Every gateway (Stripe, Chapa, Telebirr)
 * implements this. The rest of the app talks to the contract, not
 * to a concrete provider, so swapping gateways is a one-file change.
 *
 * Method shapes are deliberately narrow: we only need the operations
 * Akilil actually performs (top-up, refund, status check). Anything
 * provider-specific (subscription proration, dispute handling, etc.)
 * lives inside the gateway impl, not the contract.
 */
interface PaymentGateway
{
    /**
     * Create a hosted checkout session for the given amount.
     * Returns the URL the user should be redirected to.
     *
     * @param  int  $amountCents   Positive integer in minor units.
     * @param  string  $currency    ISO 4217 (e.g. 'USD', 'ETB').
     * @param  string  $successUrl  URL Stripe redirects to on success.
     * @param  string  $cancelUrl   URL Stripe redirects to on cancel.
     * @param  array  $metadata     Free-form key/value attached to the
     *                              session for webhook correlation.
     */
    public function createCheckoutSession(
        int $amountCents,
        string $currency,
        string $successUrl,
        string $cancelUrl,
        array $metadata = [],
    ): CheckoutSession;

    /**
     * Verify a webhook signature and parse the event payload.
     * Throws GatewayException on bad signature or unknown event.
     */
    public function parseWebhook(string $rawPayload, ?string $signatureHeader): ParsedEvent;

    /**
     * Refund a previously-completed transaction.
     * Returns the gateway's refund reference.
     */
    public function refund(string $gatewayReference, int $amountCents): string;
}