<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * A booked session between a user and a professional.
 * One row per booking; supports reschedule/cancel via status transitions.
 *
 * Race-safety: Task 3 wraps creation in a DB transaction + uses a unique
 * composite index on (user_id, scheduled_at) to prevent the same user
 * being double-booked at the same minute.
 */
return new class extends Migration {
    public function up(): void
    {
        Schema::create('appointments', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();    // the client
            $table->foreignId('professional_user_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('professional_profile_id')->nullable()->constrained('professional_profiles');

            $table->dateTime('scheduled_at');                          // UTC at rest
            $table->string('user_timezone', 64)->default('UTC');      // for display
            $table->string('professional_timezone', 64)->default('UTC');
            $table->unsignedSmallInteger('duration_minutes')->default(45);

            $table->enum('session_type', ['video', 'voice'])->default('video');

            $table->enum('status', [
                'pending',          // user requested, awaiting professional confirmation
                'confirmed',        // both sides confirmed
                'in_progress',      // session live
                'completed',
                'cancelled',
                'no_show',
                'rescheduled',
            ])->default('pending');
            $table->index('status');

            // Booking-time pricing snapshot (price changes after booking don't affect this row).
            $table->unsignedInteger('price_cents');
            $table->char('currency', 3)->default('USD');

            // Lifecycle timestamps
            $table->timestamp('confirmed_at')->nullable();
            $table->timestamp('started_at')->nullable();
            $table->timestamp('ended_at')->nullable();
            $table->timestamp('cancelled_at')->nullable();
            $table->foreignId('cancelled_by')->nullable()->constrained('users');
            $table->string('cancellation_reason', 512)->nullable();

            $table->timestamps();
            $table->softDeletes();                  // recoverable per spec

            // Hot queries: dashboard lists by role + status
            $table->index(['user_id', 'status', 'scheduled_at'], 'appt_user_status_at_idx');
            $table->index(['professional_user_id', 'status', 'scheduled_at'], 'appt_pro_status_at_idx');

            // Race-safety for the user side (Task 3).
            $table->unique(['user_id', 'scheduled_at'], 'unique_user_slot');

            // Suppress dep warnings; a mirror unique for professional-side is added in a follow-up
            // migration once Task 3's lock strategy is decided (single vs composite).
        });
    }
    public function down(): void { Schema::dropIfExists('appointments'); }
};