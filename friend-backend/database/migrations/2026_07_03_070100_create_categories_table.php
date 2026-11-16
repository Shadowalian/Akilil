<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Wellness categories — the top-level taxonomy.
 * Seeded with the five disciplines the proposal calls out:
 *   therapy, fitness, cooking, spiritual counseling, personal development.
 * Admins can add more via the dashboard (Task 6).
 */
return new class extends Migration {
    public function up(): void
    {
        Schema::create('categories', function (Blueprint $table) {
            $table->id();
            $table->string('slug', 64)->unique();      // 'therapy', 'fitness'
            $table->string('name', 128);                // 'Therapy'
            $table->string('description', 512)->nullable();
            $table->string('icon', 64)->nullable();     // Phosphor icon name
            $table->unsignedSmallInteger('sort_order')->default(0);
            $table->boolean('is_active')->default(true);
            $table->timestamps();
            $table->index('is_active');
        });
    }
    public function down(): void { Schema::dropIfExists('categories'); }
};