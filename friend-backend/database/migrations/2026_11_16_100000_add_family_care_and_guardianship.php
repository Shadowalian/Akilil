<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Family care: guardians book and pay for minors, couples / family
 * sessions bring in extra participants, and professionals declare which
 * formats and age groups they serve.
 */
return new class extends Migration {
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            // Set on teen logins created by a guardian. The guardian is the
            // account owner: they consent, book and pay.
            $table->foreignId('guardian_user_id')->nullable()->after('role')
                  ->constrained('users')->nullOnDelete();
            // What the person told us they came for at sign-up.
            $table->string('seeking_care_for', 16)->default('self')->after('date_of_birth');
            $table->string('phone', 32)->nullable()->after('email');
            $table->timestamp('terms_accepted_at')->nullable();
        });

        Schema::create('dependents', function (Blueprint $table) {
            $table->id();
            $table->foreignId('guardian_user_id')->constrained('users')->cascadeOnDelete();
            // Optional teen login (users.guardian_user_id points back).
            $table->foreignId('linked_user_id')->nullable()->constrained('users')->nullOnDelete();

            $table->string('name', 191);
            $table->date('date_of_birth');
            $table->string('gender', 24)->nullable();
            $table->string('relationship', 32);     // parent | legal_guardian | grandparent | other_relative
            $table->text('care_notes')->nullable(); // encrypted cast on the model

            // Consent of the guardian to treatment of this minor.
            $table->string('consent_version', 32);
            $table->timestamp('consent_accepted_at');
            $table->string('consent_ip', 45)->nullable();

            $table->timestamps();
            $table->softDeletes();
            $table->index('guardian_user_id');
        });

        Schema::table('professional_profiles', function (Blueprint $table) {
            $table->json('care_formats')->nullable()->after('offers_free_listening');
            $table->json('age_groups')->nullable()->after('care_formats');
            // Couples / family sessions are usually priced differently;
            // null falls back to hourly_rate_cents.
            $table->unsignedInteger('couples_rate_cents')->nullable()->after('hourly_rate_cents');
            $table->unsignedInteger('family_rate_cents')->nullable()->after('couples_rate_cents');
        });

        Schema::table('appointments', function (Blueprint $table) {
            // The rebook-after-cancel case used to hit this index and 500.
            // Active-collision checks live in AppointmentController.
            $table->dropUnique('unique_user_slot');

            $table->string('care_format', 16)->default('individual')->after('kind');
            // user_id stays the account holder who booked and pays;
            // dependent_id says which child the session is actually for.
            $table->foreignId('dependent_id')->nullable()->after('user_id')
                  ->constrained('dependents')->nullOnDelete();
            $table->unsignedInteger('refunded_cents')->default(0)->after('price_cents');
            $table->index(['user_id', 'scheduled_at'], 'appt_user_at_idx');
        });

        Schema::create('appointment_participants', function (Blueprint $table) {
            $table->id();
            $table->foreignId('appointment_id')->constrained('appointments')->cascadeOnDelete();
            $table->foreignId('user_id')->nullable()->constrained('users')->nullOnDelete();
            $table->string('name', 191);
            $table->string('email', 191)->nullable();
            $table->string('role', 24)->default('partner');   // partner | family_member
            $table->string('invite_token', 64)->unique();
            $table->string('status', 16)->default('invited'); // invited | accepted | declined
            $table->timestamp('accepted_at')->nullable();
            $table->timestamps();

            $table->index(['user_id', 'status']);
            $table->index('email');
        });

        Schema::create('intake_responses', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('dependent_id')->nullable()->constrained('dependents')->nullOnDelete();
            $table->string('pillar', 64)->nullable();
            $table->string('care_format', 16)->default('individual');
            $table->text('answers');                 // encrypted:array on the model
            $table->timestamps();
            $table->index(['user_id', 'created_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('intake_responses');
        Schema::dropIfExists('appointment_participants');

        Schema::table('appointments', function (Blueprint $table) {
            $table->dropIndex('appt_user_at_idx');
            $table->dropConstrainedForeignId('dependent_id');
            $table->dropColumn(['care_format', 'refunded_cents']);
            $table->unique(['user_id', 'scheduled_at'], 'unique_user_slot');
        });

        Schema::table('professional_profiles', function (Blueprint $table) {
            $table->dropColumn(['care_formats', 'age_groups', 'couples_rate_cents', 'family_rate_cents']);
        });

        Schema::dropIfExists('dependents');

        Schema::table('users', function (Blueprint $table) {
            $table->dropConstrainedForeignId('guardian_user_id');
            $table->dropColumn(['seeking_care_for', 'phone', 'terms_accepted_at']);
        });
    }
};
