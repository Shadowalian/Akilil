<?php

namespace App\Services\Payments;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

/**
 * Stripe gateway implementation. Talks to the Stripe REST API
 * directly via Laravel's HTTP client — this avoids pulling in the
 * `stripe/stripe-php` composer package, which is the right choice
 * for the surface Akilil actually uses (Checkout + Webhooks + Refund).
 *
 * To swap in the official SDK later, replace the HTTP::stripe(...)
 * calls with the corresponding `\Stripe\Checkout\Session::create(...)`
 * shape. The contract above is identical, so the caller code in
 * WalletService / WebhookController does not change.
 *
 * Keys are read from config('services.stripe'); the secret key is
 * used as the Authorization Bearer, the webhook secret verifies
 * the `Stripe-Signature` header (HMAC-SHA256 over `t.payload`).
 */
class StripeGateway implements PaymentGateway
{
    public function __construct(
        private readonly string $secretKey,
        private readonly string $webhookSecret,
        private readonly string $apiBase = 'https://api.stripe.com/v1',
    ) {}

    public function createCheckoutSession(
        int $amountCents,
        string $currency,
        string $successUrl,
        string $cancelUrl,
        array $metadata = [],
    ): CheckoutSession {
        $res = Http::withToken($this->secretKey)
            ->asForm()
            ->post("{$this->apiBase}/checkout/sessions", array_filter([
                'mode'              => 'payment',
                'payment_method_types[]' => 'card',
                'line_items[0][quantity]'   => 1,
                'line_items[0][price_data][currency]' => strtolower($currency),
                'line_items[0][price_data][unit_amount]' => $amountCents,
                'line_items[0][price_data][product_data][name]' => 'Akilil wallet top-up',
                'success_url' => $successUrl,
                'cancel_url'  => $cancelUrl,
                'metadata'    => $metadata,
            ], fn ($v) => $v !== null));

        if ($res->failed()) {
            Log::error('Stripe checkout session create failed', [
                'status' => $res->status(),
                'body'   => $res->body(),
            ]);
            throw new GatewayException('Failed to create checkout session: ' . $res->status());
        }
        $data = $res->json();
        return new CheckoutSession(
            url: $data['url'],
            reference: $data['id'],
            amountCents: $amountCents,
            currency: strtoupper($currency),
        );
    }

    public function parseWebhook(string $rawPayload, ?string $signatureHeader): ParsedEvent
    {
        if (! $signatureHeader) {
            throw new GatewayException('Missing Stripe-Signature header');
        }
        // Stripe-Signature looks like:  t=1234567890,v1=abcdef,v0=...
        $parts = [];
        foreach (explode(',', $signatureHeader) as $kv) {
            [$k, $v] = explode('=', $kv, 2);
            $parts[$k] = $v;
        }
        $signed = ($parts['t'] ?? '') . '.' . $rawPayload;
        $expected = hash_hmac('sha256', $signed, $this->webhookSecret);
        if (! hash_equals($expected, $parts['v1'] ?? '')) {
            throw new GatewayException('Invalid webhook signature');
        }

        $event = json_decode($rawPayload, true);
        if (! is_array($event)) {
            throw new GatewayException('Invalid webhook payload');
        }

        return match ($event['type'] ?? null) {
            'checkout.session.completed' => new ParsedEvent(
                type: $event['type'],
                reference: $event['data']['object']['id'] ?? '',
                amountCents: (int) ($event['data']['object']['amount_total'] ?? 0),
                currency: strtoupper($event['data']['object']['currency'] ?? 'USD'),
                metadata: $event['data']['object']['metadata'] ?? [],
            ),
            'charge.refunded' => new ParsedEvent(
                type: $event['type'],
                reference: $event['data']['object']['id'] ?? '',
                amountCents: (int) ($event['data']['object']['amount_refunded'] ?? 0),
                currency: strtoupper($event['data']['object']['currency'] ?? 'USD'),
                metadata: $event['data']['object']['metadata'] ?? [],
                refundedReference: $event['data']['object']['payment_intent'] ?? null,
            ),
            default => throw new GatewayException("Unhandled event type: " . ($event['type'] ?? 'unknown')),
        };
    }

    public function refund(string $gatewayReference, int $amountCents): string
    {
        $res = Http::withToken($this->secretKey)
            ->asForm()
            ->post("{$this->apiBase}/refunds", [
                'payment_intent' => $gatewayReference,
                'amount'         => $amountCents,
            ]);
        if ($res->failed()) {
            throw new GatewayException("Refund failed: {$res->status()}");
        }
        return $res->json('id') ?? throw new GatewayException('Refund returned no id');
    }
}