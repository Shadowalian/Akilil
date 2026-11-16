<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Posts inside a community channel. Posts can also be user→user via
 * channel_id = NULL, parent_post_id non-null — but those are mirrored
 * on the `messages` table for 1:1; this table is the community feed.
 */
return new class extends Migration {
    public function up(): void
    {
        Schema::create('community_posts', function (Blueprint $table) {
            $table->id();
            $table->foreignId('channel_id')->constrained('community_channels')->cascadeOnDelete();
            $table->foreignId('author_id')->constrained('users');
            $table->uuid('client_uuid')->nullable()->unique();     // offline-friendly (Task 7)
            $table->longText('content');                            // markdown
            $table->json('media')->nullable();                      // [{url, type, alt}]
            $table->foreignId('parent_post_id')->nullable()->constrained('community_posts')->nullOnDelete();
            $table->unsignedInteger('reactions_count')->default(0);
            $table->unsignedInteger('comments_count')->default(0);
            $table->enum('moderation_status', [
                'visible',
                'pending_review',
                'hidden',
                'removed',
            ])->default('visible');
            $table->index('moderation_status');
            $table->timestamps();
            $table->softDeletes();       // recoverable per spec
            $table->index(['channel_id', 'created_at', 'moderation_status'], 'posts_channel_created_mod_idx');
        });
    }
    public function down(): void { Schema::dropIfExists('community_posts'); }
};