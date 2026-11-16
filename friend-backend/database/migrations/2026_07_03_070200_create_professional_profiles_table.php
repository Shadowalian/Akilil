<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * 1:1 with users (only for users where users.role = 'professional').
 * Carries the discoverable professional attributes — NOT identity
 * (that's the users row). Soft-deletable so we can hide a professional
 * without breaking referential history (appointments still point at
 * their user_id even after a row is removed).
 */
return new class extends Migration {
    public function up(): void
    {
        Schema::create('professional_profiles', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->unique()->constrained('users')->cascadeOnDelete();

            $table->foreignId('category_id')->constrained('categories');  // primary discipline

            $table->unsignedSmallInteger('experience_years')->default(0);
            $table->text('bio')->nullable();
            $table->string('intro_video_url')->nullable();

            // Verification + badge workflow (Task 6 admin dashboard queues these).
            $table->enum('verification_status', [
                'pending',
                'in_review',
                'approved',
                'rejected',
                'revoked',
            ])->default('pending');
            $table->index('verification_status');

            $table->boolean('badge_active')->default(false);
            $table->timestamp('badge_issued_at')->nullable();
            $table->foreignId('badge_issued_by')->nullable()->constrained('users');

            // Pricing — base hourly rate in minor units of the user's currency.
            // Sessions can override at booking time. Currency follows the
            // professional's payout country at Task 8 onboarding completion.
            $table->unsignedInteger('hourly_rate_cents')->default(0);
            $table->char('currency', 3)->default('USD');
            $table->unsignedSmallInteger('session_duration_minutes')->default(45);
            $table->unsignedSmallInteger('advance_booking_hours')->default(24);

            // Aggregates (denormalised; updated by listeners on rating + appointment write).
            $table->decimal('rating_avg', 3, 2)->default(0);
            $table->unsignedInteger('rating_count')->default(0);
            $table->unsignedInteger('sessions_completed')->default(0);

            $table->boolean('is_accepting_clients')->default(true);

            $table->timestamps();
            $table->softDeletes();

            // Hot discovery queries — category + accepting + verified.
            $table->index(['verification_status', 'is_accepting_clients'], 'pro_status_accepting_idx');
            $table->index('rating_avg');
        });
    }
    public function down(): void { Schema::dropIfExists('professional_profiles'); }
};