<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * User-flagged content. subject_type is polymorphic across posts,
 * comments, messages, vents, journal entries. The admin moderation
 * queue (Task 6) processes these.
 */
return new class extends Migration {
    public function up(): void
    {
        Schema::create('community_reports', function (Blueprint $table) {
            $table->id();
            $table->foreignId('reporter_id')->constrained('users');
            $table->morphs('subject');   // subject_type + subject_id
            $table->enum('reason', [
                'spam',
                'harassment',
                'self_harm_concern',
                'misinformation',
                'inappropriate',
                'other',
            ]);
            $table->text('description')->nullable();
            $table->enum('status', [
                'pending',
                'in_review',
                'action_taken',
                'dismissed',
            ])->default('pending');
            $table->index('status');
            $table->foreignId('resolved_by')->nullable()->constrained('users');
            $table->timestamp('resolved_at')->nullable();
            $table->text('resolution_notes')->nullable();
            $table->timestamps();
        });
    }
    public function down(): void { Schema::dropIfExists('community_reports'); }
};