<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * The actual video/voice session record (created when /session/start
 * is called in Task 4). Linked 1:1 to the appointment once started.
 *
 * "sessions" was avoided as a table name to prevent collision with the
 * PHP `session_*` global APIs and Sanctum's personal_access_tokens.
 */
return new class extends Migration {
    public function up(): void
    {
        Schema::create('call_sessions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('appointment_id')->unique()->constrained('appointments')->cascadeOnDelete();

            $table->timestamp('started_at');
            $table->timestamp('ended_at')->nullable();
            $table->unsignedInteger('duration_seconds')->nullable();

            // WebRTC provider integration (Jitsi in our case).
            $table->string('provider', 32)->default('jitsi');
            $table->string('room_name', 191);
            $table->text('room_token')->nullable();   // JWT for self-hosted Jitsi (Task 4)

            $table->string('recording_url', 1024)->nullable();
            $table->unsignedInteger('recording_size_bytes')->nullable();
            $table->unsignedInteger('recording_duration_seconds')->nullable();
            $table->enum('recording_status', ['none', 'pending', 'ready', 'failed'])->default('none');

            $table->enum('status', ['active', 'completed', 'failed', 'cancelled'])->default('active');
            $table->index('status');

            $table->timestamps();
            $table->softDeletes();
        });
    }
    public function down(): void { Schema::dropIfExists('call_sessions'); }
};