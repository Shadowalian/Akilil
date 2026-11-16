<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Discrete mood-log events (separate from the journal's per-entry mood).
 * Source tracks where it came from: 'manual', 'journal', 'checkin', 'widget'.
 * Analytics aggregated by day/week/month in Task 5.
 */
return new class extends Migration {
    public function up(): void
    {
        Schema::create('mood_logs', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->unsignedTinyInteger('mood_score');    // 1..10
            $table->json('mood_tags')->nullable();
            $table->string('source', 32)->default('manual'); // manual|journal|checkin|widget|app
            $table->string('note', 512)->nullable();
            $table->timestamp('logged_at');                // when it happened, not when row was written

            $table->timestamps();
            $table->index(['user_id', 'logged_at']);
        });
    }
    public function down(): void { Schema::dropIfExists('mood_logs'); }
};