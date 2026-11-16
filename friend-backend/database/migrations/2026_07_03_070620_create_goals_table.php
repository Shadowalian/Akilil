<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * User-defined goal with target + progress. Progress is a percentage 0..100.
 * "target" is a free-text unit (e.g. "10 sessions a month", "30 pushups/day").
 */
return new class extends Migration {
    public function up(): void
    {
        Schema::create('goals', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->string('title', 191);
            $table->text('description')->nullable();
            $table->string('target', 191)->nullable();          // human-readable target
            $table->unsignedSmallInteger('progress')->default(0);   // 0..100
            $table->date('due_date')->nullable();
            $table->enum('status', ['active', 'paused', 'completed', 'archived'])->default('active');
            $table->index('status');
            $table->timestamps();
        });
    }
    public function down(): void { Schema::dropIfExists('goals'); }
};