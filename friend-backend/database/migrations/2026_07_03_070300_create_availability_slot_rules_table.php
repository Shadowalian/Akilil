<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Recurring weekly availability for a professional.
 * One row per (weekday, start_time, end_time) — e.g. "every Tuesday 14:00–18:00".
 * Concrete bookable slots are COMPUTED at query time by Task 3's
 * `getAvailableSlots` endpoint (so changes to existing appointments
 * cancel conflict slots immediately).
 *
 * Also supports EXCEPTIONS via availability_blocks.
 */
return new class extends Migration {
    public function up(): void
    {
        Schema::create('availability_slot_rules', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            // 1=Mon … 7=Sun (ISO). Use smallint + check constraint via app layer.
            $table->unsignedTinyInteger('weekday');                   // 1..7
            $table->time('start_time');
            $table->time('end_time');
            $table->unsignedSmallInteger('slot_duration_minutes')->default(45);
            $table->unsignedSmallInteger('buffer_minutes')->default(0);
            $table->string('timezone', 64)->default('UTC');           // the TZ these times are in
            $table->date('effective_from')->nullable();
            $table->date('effective_until')->nullable();
            $table->boolean('is_active')->default(true);
            $table->timestamps();

            $table->index(['user_id', 'weekday', 'is_active'], 'avail_user_wday_active_idx');
        });
    }
    public function down(): void { Schema::dropIfExists('availability_slot_rules'); }
};