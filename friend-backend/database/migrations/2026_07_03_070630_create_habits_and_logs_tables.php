<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Habits a user wants to track daily (e.g. "Drink 8 glasses of water").
 * One habit + many habit_logs (one per completion event / per day).
 * Streak computation done at query time (Task 5 analytics).
 */
return new class extends Migration {
    public function up(): void
    {
        Schema::create('habits', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->string('title', 191);
            $table->text('description')->nullable();
            $table->string('cadence', 32)->default('daily');  // daily|weekdays|weekly|custom
            $table->json('days_of_week')->nullable();         // [1,3,5] for Mon/Wed/Fri
            $table->string('icon', 64)->nullable();
            $table->string('color_token', 32)->nullable();   // matches a palette token
            $table->boolean('is_archived')->default(false);
            $table->timestamps();
            $table->index(['user_id', 'is_archived'], 'habits_user_archived_idx');
        });

        Schema::create('habit_logs', function (Blueprint $table) {
            $table->id();
            $table->foreignId('habit_id')->constrained('habits')->cascadeOnDelete();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->date('log_date');                 // one row per habit per day typically
            $table->boolean('completed')->default(true);
            $table->text('note')->nullable();
            $table->timestamps();
            $table->unique(['habit_id', 'log_date']);
            $table->index(['user_id', 'log_date']);
        });
    }
    public function down(): void
    {
        Schema::dropIfExists('habit_logs');
        Schema::dropIfExists('habits');
    }
};