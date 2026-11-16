<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * A "vent" — short text or voice post the user wants to put out into
 * the world. Can be anonymous (author_user_id null) and/or time-limited
 * (expires_at). Flagged by the Task 5 crisis-detection pipeline.
 */
return new class extends Migration {
    public function up(): void
    {
        Schema::create('vents', function (Blueprint $table) {
            $table->id();
            $table->foreignId('author_user_id')->nullable()->constrained('users')->nullOnDelete();

            $table->enum('content_type', ['text', 'voice'])->default('text');
            $table->text('content')->nullable();               // text body
            $table->string('voice_path', 512)->nullable();     // audio file on private disk
            $table->unsignedInteger('voice_duration_seconds')->nullable();

            $table->boolean('is_anonymous')->default(false);
            $table->dateTime('expires_at')->nullable();
            $table->index('expires_at');

            $table->enum('flagged_status', [
                'none',
                'pending_review',
                'cleared',
                'auto_hidden',
            ])->default('none');
            $table->index('flagged_status');

            $table->unsignedInteger('reactions_count')->default(0);
            $table->unsignedInteger('comments_count')->default(0);

            $table->timestamps();
            $table->softDeletes();      // recoverable per spec
            $table->index(['created_at', 'flagged_status'], 'vents_created_flagged_idx');
        });
    }
    public function down(): void { Schema::dropIfExists('vents'); }
};