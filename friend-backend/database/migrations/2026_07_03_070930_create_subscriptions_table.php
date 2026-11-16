<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * A user's active subscription. One row per active subscription per user
 * (historical subscriptions archived via separate logic in Task 9).
 * gateway_subscription_id is the gateway's recurring-subscription handle.
 */
return new class extends Migration {
    public function up(): void
    {
        Schema::create('subscriptions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('plan_id')->constrained('subscription_plans');

            $table->enum('status', [
                'trialing',
                'active',
                'past_due',
                'cancelled',
                'expired',
            ])->default('trialing');
            $table->index('status');

            $table->string('gateway', 32)->nullable();
            $table->string('gateway_subscription_id', 191)->nullable();
            $table->index(['gateway', 'gateway_subscription_id']);

            $table->timestamp('trial_ends_at')->nullable();
            $table->timestamp('current_period_starts_at')->nullable();
            $table->timestamp('current_period_ends_at')->nullable();
            $table->timestamp('cancelled_at')->nullable();
            $table->boolean('cancel_at_period_end')->default(false);

            $table->timestamps();
            $table->index(['user_id', 'status'], 'subs_user_status_idx');
        });
    }
    public function down(): void { Schema::dropIfExists('subscriptions'); }
};