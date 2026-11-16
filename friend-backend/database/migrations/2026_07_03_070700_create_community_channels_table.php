<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Community channels — topical, admin/moderator-managed.
 * channel_type covers "support circle", "challenge", "discipline talk".
 */
return new class extends Migration {
    public function up(): void
    {
        Schema::create('community_channels', function (Blueprint $table) {
            $table->id();
            $table->foreignId('created_by')->constrained('users');
            $table->string('slug', 64)->unique();
            $table->string('name', 128);
            $table->text('description')->nullable();
            $table->enum('channel_type', [
                'support_circle',
                'challenge',
                'discipline_talk',
                'announcement',
            ])->default('support_circle');
            $table->boolean('is_private')->default(false);    // invite-only via membership
            $table->boolean('is_archived')->default(false);
            $table->string('cover_image_path')->nullable();
            $table->unsignedInteger('member_count')->default(0);
            $table->timestamps();
            $table->softDeletes();        // recoverable per spec
            $table->index(['is_archived', 'channel_type'], 'channels_archived_type_idx');
        });
    }
    public function down(): void { Schema::dropIfExists('community_channels'); }
};