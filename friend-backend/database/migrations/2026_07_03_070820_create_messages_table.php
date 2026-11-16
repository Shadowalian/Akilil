<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * A single message in a conversation. Encrypted content body in Task 10.
 * Reply/edit/delete semantics deferred to Task 4 (chat endpoints).
 */
return new class extends Migration {
    public function up(): void
    {
        Schema::create('messages', function (Blueprint $table) {
            $table->id();
            $table->uuid('client_uuid')->nullable()->unique();   // offline-friendly (Task 7)
            $table->foreignId('conversation_id')->constrained('conversations')->cascadeOnDelete();
            $table->foreignId('sender_id')->nullable()->constrained('users')->nullOnDelete();
            $table->foreignId('parent_message_id')->nullable()->constrained('messages')->nullOnDelete();

            $table->enum('message_type', ['text', 'voice', 'image', 'file', 'system'])->default('text');
            $table->longText('content_encrypted')->nullable();         // Task 10 encrypts body
            $table->string('media_path')->nullable();                  // on PRIVATE_DISK
            $table->unsignedInteger('media_size_bytes')->nullable();
            $table->unsignedInteger('media_duration_seconds')->nullable();   // voice

            $table->boolean('is_edited')->default(false);
            $table->boolean('is_deleted')->default(false);
            $table->enum('flagged_status', ['none', 'pending_review', 'cleared', 'auto_hidden'])
                  ->default('none');
            $table->index('flagged_status');

            $table->timestamps();
            $table->index(['conversation_id', 'created_at'], 'msgs_conv_created_idx');
        });

        // Now that messages exists, attach the backref on conversations.last_message_id.
        Schema::table('conversations', function (Blueprint $table) {
            $table->foreign('last_message_id')->references('id')->on('messages')->nullOnDelete();
        });
        // And the per-user read state on conversation_participants.last_read_message_id.
        Schema::table('conversation_participants', function (Blueprint $table) {
            $table->foreign('last_read_message_id', 'cp_last_read_fk')
                  ->references('id')->on('messages')->nullOnDelete();
        });
    }
    public function down(): void
    {
        Schema::table('conversation_participants', function (Blueprint $table) {
            $table->dropForeign('cp_last_read_fk');
        });
        Schema::table('conversations', function (Blueprint $table) {
            $table->dropForeign(['last_message_id']);
        });
        Schema::dropIfExists('messages');
    }
};