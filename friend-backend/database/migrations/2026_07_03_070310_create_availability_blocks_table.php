<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * One-off availability blocks (vacations, emergencies, ad-hoc time-off).
 * A date range that disables slot computation underneath it.
 */
return new class extends Migration {
    public function up(): void
    {
        Schema::create('availability_blocks', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->dateTime('start_at');
            $table->dateTime('end_at');
            $table->string('reason', 255)->nullable();   // 'Travel', 'Sick', etc.
            $table->timestamps();
            $table->index(['user_id', 'start_at', 'end_at'], 'blocks_user_range_idx');
        });
    }
    public function down(): void { Schema::dropIfExists('availability_blocks'); }
};