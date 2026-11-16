<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Membership in community channels. Holds role for moderation within
 * the channel. PRIVILEGE: a user with role 'channel_admin' on a channel
 * can pin/moderate that channel only — independent of platform roles.
 */
return new class extends Migration {
    public function up(): void
    {
        Schema::create('community_channel_members', function (Blueprint $table) {
            $table->id();
            $table->foreignId('channel_id')->constrained('community_channels')->cascadeOnDelete();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->enum('role', ['member', 'moderator', 'channel_admin'])->default('member');
            $table->boolean('is_muted')->default(false);
            $table->timestamp('last_read_at')->nullable();
            $table->timestamps();

            $table->unique(['channel_id', 'user_id']);
            $table->index(['user_id', 'role']);
        });
    }
    public function down(): void { Schema::dropIfExists('community_channel_members'); }
};