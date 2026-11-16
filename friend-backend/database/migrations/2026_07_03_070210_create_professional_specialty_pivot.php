<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Many-to-many pivot: professional ↔ specialty.
 * Composite primary key (professional_profile_id, specialty_id).
 * Column name follows Laravel's BelongsToMany convention so the
 * ProfessionalProfile::specialties() relationship resolves cleanly
 * without custom pivot-key overrides.
 */
return new class extends Migration {
    public function up(): void
    {
        Schema::create('professional_specialty', function (Blueprint $table) {
            $table->foreignId('professional_profile_id')->constrained('professional_profiles')->cascadeOnDelete();
            $table->foreignId('specialty_id')->constrained('specialties')->cascadeOnDelete();
            $table->primary(['professional_profile_id', 'specialty_id']);
        });
    }
    public function down(): void { Schema::dropIfExists('professional_specialty'); }
};