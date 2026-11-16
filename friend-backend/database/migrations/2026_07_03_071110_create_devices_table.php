<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Per-user registered devices for push delivery (FCM/APNs).
 * One user can have many devices; the Flutter apps register on login.
 * Task 4 deactivates devices that return INVALID_REGISTRATION from FCM.
 */
return new class extends Migration {
    public function up(): void
    {
        Schema::create('devices', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->enum('platform', ['ios', 'android', 'web'])->default('android');
            $table->string('push_token', 512);          // FCM token or APNs token
            $table->string('app_version', 32)->nullable();
            $table->string('os_version', 32)->nullable();
            $table->string('device_model', 64)->nullable();
            $table->enum('locale', ['en', 'am', 'om', 'sw'])->default('en');
            $table->boolean('is_active')->default(true);
            $table->timestamp('last_seen_at')->nullable();
            $table->timestamps();
            $table->unique(['user_id', 'push_token']);
            $table->index(['is_active', 'platform']);
        });
    }
    public function down(): void { Schema::dropIfExists('devices'); }
};