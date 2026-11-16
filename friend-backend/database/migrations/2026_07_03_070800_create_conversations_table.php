<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * 1:1 and group conversation threads.
 * Two participants = direct; many via conversation_participants = group.
 * Task 4 adds encrypted message bodies; this row is just metadata.
 */
return new class extends Migration {
    public function up(): void
    {
        Schema::create('conversations', function (Blueprint $table) {
            $table->id();
            $table->enum('type', ['direct', 'group'])->default('direct');
            $table->string('title', 191)->nullable();   // only for groups
            $table->foreignId('created_by')->constrained('users');
            $table->json('settings')->nullable();       // mute, encryption keys, etc.
            $table->foreignId('last_message_id')->nullable();  // backref added after messages table
            $table->timestamp('last_message_at')->nullable();
            $table->timestamps();
            $table->softDeletes();
            $table->index('last_message_at');
        });
    }
    public function down(): void { Schema::dropIfExists('conversations'); }
};