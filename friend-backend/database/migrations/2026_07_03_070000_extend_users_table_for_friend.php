<?php

/**
 * Extends the default Laravel users table with Akilil-platform fields.
 *
 * Adds:
 *   - role enum (user/professional/admin/support/moderator)
 *       defaults to 'user'; spatie/laravel-permission handles admin/
 *       support/moderator separately, but mirrors role here for fast
 *       UI-routing queries that don't need a join.
 *   - locale, timezone (drives Flutter app language + Jitsi time display)
 *   - last_seen_at (presence channel hint)
 *   - 2FA fields (TOTP secret + recovery codes + confirmed_at)
 *   - soft deletes (deleted_at) — recoverable per spec
 *   - avatar_url, gender, date_of_birth (profile basics, optional)
 */

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            // Persona routing column. Indexed because the discovery + admin
            // modules filter on it constantly.
            $table->enum('role', ['user', 'professional'])
                  ->default('user')
                  ->after('id');
            $table->index('role');

            $table->string('locale', 8)->default('en')->after('email');
            $table->string('timezone', 64)->default('UTC')->after('locale');

            $table->string('avatar_path')->nullable()->after('timezone');
            $table->enum('gender', ['female', 'male', 'non_binary', 'prefer_not_to_say'])->nullable();
            $table->date('date_of_birth')->nullable();

            // 2FA (TOTP) — Task 2 enforces admin-side; Task 7/8 adds opt-in for users.
            $table->text('totp_secret')->nullable();        // encrypted at rest in Task 10
            $table->boolean('totp_enabled')->default(false);
            $table->json('totp_recovery_codes')->nullable();
            $table->timestamp('totp_confirmed_at')->nullable();

            $table->timestamp('last_seen_at')->nullable();
            $table->index('last_seen_at');

            $table->softDeletes();
            $table->index('deleted_at');
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropIndex(['role']);
            $table->dropIndex(['last_seen_at']);
            $table->dropIndex(['deleted_at']);
            $table->dropSoftDeletes();
            $table->dropColumn([
                'role', 'locale', 'timezone', 'avatar_path',
                'gender', 'date_of_birth',
                'totp_secret', 'totp_enabled', 'totp_recovery_codes', 'totp_confirmed_at',
                'last_seen_at',
            ]);
        });
    }
};