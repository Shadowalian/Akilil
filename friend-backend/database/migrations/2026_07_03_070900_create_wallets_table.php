<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * A user's wallet — single balance, currency-per-wallet.
 * Locked during /api/payments transactions (Task 9) for atomicity.
 */
return new class extends Migration {
    public function up(): void
    {
        Schema::create('wallets', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->unique()->constrained('users')->cascadeOnDelete();
            $table->char('currency', 3)->default('USD');
            $table->bigInteger('balance_cents')->default(0);   // user-stored credits
            $table->bigInteger('pending_cents')->default(0);   // in-flight
            $table->bigInteger('lifetime_topup_cents')->default(0);
            $table->bigInteger('lifetime_spent_cents')->default(0);
            $table->unsignedInteger('version')->default(0);    // optimistic-lock counter
            $table->timestamps();
        });
    }
    public function down(): void { Schema::dropIfExists('wallets'); }
};