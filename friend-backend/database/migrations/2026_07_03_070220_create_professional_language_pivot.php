<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Many-to-many pivot: professional ↔ language. Carries proficiency.
 * Column name follows Laravel's BelongsToMany convention so the
 * ProfessionalProfile::languages() relationship resolves cleanly.
 */
return new class extends Migration {
    public function up(): void
    {
        Schema::create('professional_language', function (Blueprint $table) {
            $table->foreignId('professional_profile_id')->constrained('professional_profiles')->cascadeOnDelete();
            $table->foreignId('language_id')->constrained('languages')->cascadeOnDelete();
            $table->enum('proficiency', ['basic', 'conversational', 'fluent', 'native'])->default('fluent');
            $table->primary(['professional_profile_id', 'language_id']);
        });
    }
    public function down(): void { Schema::dropIfExists('professional_language'); }
};