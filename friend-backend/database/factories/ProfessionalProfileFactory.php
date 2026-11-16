<?php

namespace Database\Factories;

use App\Models\Category;
use App\Models\ProfessionalProfile;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<ProfessionalProfile>
 */
class ProfessionalProfileFactory extends Factory
{
    protected $model = ProfessionalProfile::class;

    public function definition(): array
    {
        $hourly = fake()->randomElement([3000, 4500, 6000, 7500, 9000, 12000]); // minor units
        return [
            'user_id'                   => User::factory()->professional(),
            'category_id'               => Category::factory(),
            'experience_years'          => fake()->numberBetween(1, 25),
            'bio'                       => fake()->paragraph(3),
            'intro_video_url'           => null,
            'verification_status'       => fake()->randomElement(['approved', 'approved', 'approved', 'pending', 'in_review']),
            'badge_active'              => true,
            'badge_issued_at'           => now(),
            'badge_issued_by'           => null,
            'hourly_rate_cents'         => $hourly,
            'currency'                  => 'USD',
            'session_duration_minutes'  => 45,
            'advance_booking_hours'     => 24,
            'rating_avg'                => fake()->randomFloat(2, 3.5, 5.0),
            'rating_count'              => fake()->numberBetween(0, 80),
            'sessions_completed'        => fake()->numberBetween(0, 200),
            'is_accepting_clients'      => true,
        ];
    }

    public function approved(): self
    {
        return $this->state(fn () => ['verification_status' => 'approved', 'badge_active' => true]);
    }
}