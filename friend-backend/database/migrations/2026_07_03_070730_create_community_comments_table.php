<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Comments on community posts (also task 5/6 may extend to user→user via
 * conversations table).
 */
return new class extends Migration {
    public function up(): void
    {
        Schema::create('community_comments', function (Blueprint $table) {
            $table->id();
            $table->foreignId('post_id')->constrained('community_posts')->cascadeOnDelete();
            $table->foreignId('author_id')->constrained('users');
            $table->text('content');
            $table->foreignId('parent_comment_id')->nullable()->constrained('community_comments')->nullOnDelete();
            $table->enum('moderation_status', [
                'visible', 'pending_review', 'hidden', 'removed',
            ])->default('visible');
            $table->timestamps();
            $table->softDeletes();
            $table->index(['post_id', 'created_at'], 'comments_post_created_idx');
        });
    }
    public function down(): void { Schema::dropIfExists('community_comments'); }
};