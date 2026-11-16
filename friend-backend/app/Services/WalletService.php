<?php

namespace App\Services;

use App\Models\Transaction;
use App\Models\User;
use App\Models\Wallet;
use App\Services\Payments\PaymentGateway;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

/**
 * WalletService — the single entry point for moving money into /
 * out of a user's wallet.
 *
 * Why a service: every state change involves a wallet (read),
 * a transaction (write), and a gateway call (side effect). Keeping
 * this in one place ensures:
 *   - DB::transaction wraps every mutation (no double-credit)
 *   - Optimistic locking via the `version` column
 *   - Wallet is auto-created on first use (lazy)
 *   - Refunds always create a NEW transaction (no mutation in place)
 */
class WalletService
{
    public function __construct(private readonly PaymentGateway $gateway) {}

    /**
     * The user's wallet, created on first use. A user has exactly one
     * wallet (wallets.user_id is unique) in the platform currency.
     */
    public function walletFor(User $user, ?string $currency = null): Wallet
    {
        return Wallet::firstOrCreate(
            ['user_id' => $user->id],
            ['currency' => $currency ?: config('akilil.currency'), 'balance_cents' => 0, 'pending_cents' => 0],
        );
    }

    /** True when the wallet can cover a charge in this currency. */
    public function canAfford(User $user, int $amountCents, string $currency): bool
    {
        $wallet = $this->walletFor($user, $currency);

        return $wallet->currency === $currency && $wallet->balance_cents >= $amountCents;
    }

    /**
     * Begin a top-up: creates a Transaction in `pending` and returns
     * a CheckoutSession the user is redirected to. On webhook
     * `checkout.session.completed`, the controller calls
     * [completeTopup] to flip the transaction to `succeeded` and
     * credit the wallet.
     */
    public function beginTopup(User $user, int $amountCents, string $currency = 'USD'): array
    {
        $wallet = $this->walletFor($user, $currency);

        $tx = DB::transaction(function () use ($user, $wallet, $amountCents, $currency) {
            return Transaction::create([
                'wallet_id'   => $wallet->id,
                'user_id'     => $user->id,
                'type'        => 'topup',
                'status'      => 'pending',
                'amount_cents' => $amountCents,
                'currency'    => $currency,
            ]);
        });

        $session = $this->gateway->createCheckoutSession(
            amountCents: $amountCents,
            currency: $currency,
            successUrl: config('app.frontend_url') . '/wallet?status=success',
            cancelUrl:  config('app.frontend_url') . '/wallet?status=cancel',
            metadata: ['transaction_id' => $tx->id, 'user_id' => $user->id],
        );

        $tx->update([
            'gateway'           => 'stripe', // or detect from gateway class
            'gateway_reference' => $session->reference,
        ]);

        return ['transaction' => $tx, 'session' => $session];
    }

    /**
     * Webhook landing: the user paid. Flip the pending transaction
     * to `succeeded`, credit the wallet, and bump the version (so
     * any concurrent debits retry).
     */
    public function completeTopup(string $gatewayReference, array $metadata = []): Transaction
    {
        return DB::transaction(function () use ($gatewayReference, $metadata) {
            $tx = Transaction::where('gateway_reference', $gatewayReference)
                ->lockForUpdate()
                ->firstOrFail();
            if ($tx->status === 'succeeded') {
                return $tx; // idempotent
            }
            $tx->update([
                'status'        => 'succeeded',
                'processed_at'  => now(),
                'gateway_payload' => $metadata,
            ]);
            // Optimistic wallet credit. If the row version changed
            // between read and write we retry up to 3 times.
            for ($i = 0; $i < 3; $i++) {
                $wallet = Wallet::where('id', $tx->wallet_id)->lockForUpdate()->first();
                $newVersion = $wallet->version + 1;
                $updated = Wallet::where('id', $wallet->id)
                    ->where('version', $wallet->version)
                    ->update([
                        'balance_cents'         => $wallet->balance_cents + $tx->amount_cents,
                        'lifetime_topup_cents'  => $wallet->lifetime_topup_cents + $tx->amount_cents,
                        'version'               => $newVersion,
                    ]);
                if ($updated) break;
            }
            return $tx;
        });
    }

    /**
     * Spend from the user's wallet (e.g. to pay a pro). Returns
     * the resulting transaction or throws if balance is insufficient.
     */
    public function debit(User $user, int $amountCents, string $currency, string $type, $reference = null): Transaction
    {
        return DB::transaction(function () use ($user, $amountCents, $currency, $type, $reference) {
            $this->walletFor($user, $currency);
            $wallet = Wallet::where('user_id', $user->id)->lockForUpdate()->firstOrFail();
            if ($wallet->currency !== $currency) {
                throw new \DomainException('Wallet currency does not match this charge');
            }
            if ($wallet->balance_cents < $amountCents) {
                throw new \DomainException('Insufficient wallet balance');
            }
            $tx = Transaction::create([
                'wallet_id'   => $wallet->id,
                'user_id'     => $user->id,
                'type'        => $type,
                'status'      => 'succeeded',
                'amount_cents' => $amountCents,
                'currency'    => $currency,
                'processed_at' => now(),
                'reference_type' => $reference ? get_class($reference) : null,
                'reference_id'   => $reference?->getKey(),
            ]);
            Wallet::where('id', $wallet->id)
                ->where('version', $wallet->version)
                ->update([
                    'balance_cents'        => $wallet->balance_cents - $amountCents,
                    'lifetime_spent_cents' => $wallet->lifetime_spent_cents + $amountCents,
                    'version'              => $wallet->version + 1,
                ]);
            return $tx;
        });
    }

    /**
     * Put money back into a wallet without touching the gateway — used for
     * cancellation refunds of wallet-paid sessions and seats. The money
     * never left the platform, so this is a pure ledger entry.
     */
    public function credit(User $user, int $amountCents, string $currency, string $type = 'refund', $reference = null, ?string $reason = null): Transaction
    {
        return DB::transaction(function () use ($user, $amountCents, $currency, $type, $reference, $reason) {
            $this->walletFor($user, $currency);
            $wallet = Wallet::where('user_id', $user->id)->lockForUpdate()->firstOrFail();
            $tx = Transaction::create([
                'wallet_id'    => $wallet->id,
                'user_id'      => $user->id,
                'type'         => $type,
                'status'       => 'succeeded',
                'amount_cents' => $amountCents,
                'currency'     => $currency,
                'processed_at' => now(),
                'reference_type' => $reference ? get_class($reference) : null,
                'reference_id'   => $reference?->getKey(),
                'failure_reason' => $reason,
            ]);
            $wallet->update([
                'balance_cents' => $wallet->balance_cents + $amountCents,
                'version'       => $wallet->version + 1,
            ]);

            return $tx;
        });
    }

    /**
     * Refund a previously-succeeded transaction. Creates a NEW
     * transaction (positive amount) and credits the wallet. Calls
     * the gateway for the actual money movement; if the gateway
     * call fails the local credit is rolled back.
     */
    public function refund(Transaction $original, string $reason = 'admin_refund'): Transaction
    {
        return DB::transaction(function () use ($original, $reason) {
            $ref = $this->gateway->refund(
                gatewayReference: $original->gateway_reference ?? $original->id,
                amountCents: $original->amount_cents,
            );
            $tx = Transaction::create([
                'wallet_id'   => $original->wallet_id,
                'user_id'     => $original->user_id,
                'type'        => 'refund',
                'status'      => 'succeeded',
                'amount_cents' => $original->amount_cents,
                'currency'    => $original->currency,
                'gateway'     => $original->gateway,
                'gateway_reference' => $ref,
                'reference_type' => Transaction::class,
                'reference_id'   => $original->id,
                'processed_at' => now(),
                'failure_reason' => $reason,
            ]);
            $wallet = Wallet::where('id', $original->wallet_id)->lockForUpdate()->first();
            Wallet::where('id', $wallet->id)
                ->where('version', $wallet->version)
                ->update([
                    'balance_cents' => $wallet->balance_cents + $original->amount_cents,
                    'version'       => $wallet->version + 1,
                ]);
            $original->update(['status' => 'refunded']);
            return $tx;
        });
    }
}