<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Every money-in or money-out event. Polymorphic `reference` ties to the
 * appointment (payment), the subscription (recurring), the payout record,
 * or a refund. gateway_reference is the gateway's tx id (Stripe, Chapa,
 * Telebirr, etc.). Webhook handlers (Task 9) update this row's status
 * atomically after signature verification.
 */
return new class extends Migration {
    public function up(): void
    {
        Schema::create('transactions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('wallet_id')->constrained('wallets')->cascadeOnDelete();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();

            $table->enum('type', [
                'payment',     // user → platform (for a session)
                'payout',      // platform → professional
                'refund',      // platform → user (cancellation/refund)
                'topup',       // user → wallet
                'subscription',
                'adjustment',
            ]);
            $table->index('type');

            $table->enum('status', [
                'pending',
                'processing',
                'succeeded',
                'failed',
                'cancelled',
                'refunded',
            ])->default('pending');
            $table->index('status');

            $table->bigInteger('amount_cents');
            $table->char('currency', 3)->default('USD');
            $table->char('fee_cents_currency', 3)->nullable();
            $table->bigInteger('fee_cents')->default(0);

            $table->string('gateway', 32)->nullable();               // 'stripe'|'chapa'|'telebirr'|null
            $table->string('gateway_reference', 191)->nullable();    // gateway tx id
            $table->json('gateway_payload')->nullable();             // webhook body (truncated)
            $table->index(['gateway', 'gateway_reference']);

            $table->morphs('reference');    // reference_type + reference_id

            $table->text('failure_reason')->nullable();
            $table->timestamp('processed_at')->nullable();

            $table->timestamps();
            $table->softDeletes();
            $table->index(['user_id', 'created_at'], 'tx_user_created_idx');
        });
    }
    public function down(): void { Schema::dropIfExists('transactions'); }
};