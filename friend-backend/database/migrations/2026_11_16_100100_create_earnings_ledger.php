<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * What a professional has actually earned, net of the platform fee.
 * One row per paid thing (completed session, group seat, live gift).
 * Payout requests are validated against the sum of `available` rows.
 */
return new class extends Migration {
    public function up(): void
    {
        Schema::create('earnings', function (Blueprint $table) {
            $table->id();
            $table->foreignId('professional_user_id')->constrained('users')->cascadeOnDelete();
            $table->string('kind', 24);                 // session | group_seat | gift
            $table->string('source_type');
            $table->unsignedBigInteger('source_id');
            $table->bigInteger('gross_cents');
            $table->bigInteger('fee_cents');
            $table->bigInteger('net_cents');
            $table->char('currency', 3);
            $table->string('status', 16)->default('available');   // available | reversed
            $table->timestamps();

            // One earning per source: makes recording idempotent.
            $table->unique(['source_type', 'source_id'], 'earnings_source_unique');
            $table->index(['professional_user_id', 'status', 'created_at'], 'earnings_pro_status_idx');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('earnings');
    }
};
