<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * User's private wellness journal. Fully private — only the owner can read.
 * client_uuid is for client-side generated entries that get synced later
 * (Task 7 offline support); conflicts resolved by created_at.
 */
return new class extends Migration {
    public function up(): void
    {
        Schema::create('journal_entries', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();

            $table->uuid('client_uuid')->nullable()->unique();
            $table->unsignedTinyInteger('mood_score')->nullable();         // 1..10
            $table->json('mood_tags')->nullable();                         // ['anxious','tired','focused']
            $table->longText('content');                                   // markdown
            $table->boolean('is_private')->default(true);
            $table->dateTime('created_client_at')->nullable();             // when the user wrote it locally

            $table->timestamps();
            $table->index(['user_id', 'created_at']);
        });
    }
    public function down(): void { Schema::dropIfExists('journal_entries'); }
};