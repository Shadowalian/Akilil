<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * A scheduled payout to a professional from their session earnings.
 * status transitions: scheduled → processing → succeeded/failed.
 * Task 9 wires actual money-movement via Stripe Connect or local bank
 * disbursement; this table records the lifecycle.
 */
return new class extends Migration {
    public function up(): void
    {
        Schema::create('payouts', function (Blueprint $table) {
            $table->id();
            $table->foreignId('professional_user_id')->constrained('users')->cascadeOnDelete();

            $table->bigInteger('amount_cents');
            $table->char('currency', 3)->default('USD');
            $table->bigInteger('platform_fee_cents')->default(0);    // the commission

            $table->enum('status', [
                'scheduled',
                'processing',
                'succeeded',
                'failed',
                'cancelled',
            ])->default('scheduled');
            $table->index('status');

            $table->string('gateway', 32)->nullable();
            $table->string('gateway_payout_id', 191)->nullable();
            $table->index(['gateway', 'gateway_payout_id']);

            $table->date('scheduled_for');
            $table->index('scheduled_for');

            $table->timestamp('processed_at')->nullable();
            $table->text('failure_reason')->nullable();

            $table->timestamps();
            $table->softDeletes();
        });
    }
    public function down(): void { Schema::dropIfExists('payouts'); }
};