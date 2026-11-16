<?php

namespace Database\Factories;

use App\Models\ProfessionalDocument;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Str;

/**
 * @extends Factory<ProfessionalDocument>
 */
class ProfessionalDocumentFactory extends Factory
{
    protected $model = ProfessionalDocument::class;

    public function definition(): array
    {
        return [
            'user_id' => User::factory()->professional(),
            'document_type' => fake()->randomElement(['government_id', 'professional_license', 'certification']),
            'file_path' => 'professionals/' . Str::uuid() . '.pdf',
            'original_filename' => fake()->word() . '.pdf',
            'size_bytes' => fake()->numberBetween(50_000, 5_000_000),
            'mime_type' => 'application/pdf',
            'description' => fake()->sentence(),
            'review_status' => 'pending',
            'reviewed_by' => null,
            'reviewed_at' => null,
            'review_notes' => null,
        ];
    }
}