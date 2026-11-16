<?php

namespace Database\Factories;

use App\Models\MoodLog;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<MoodLog>
 */
class MoodLogFactory extends Factory
{
    protected $model = MoodLog::class;

    public function definition(): array
    {
        return [
            'user_id'    => User::factory(),
            'mood_score' => fake()->numberBetween(1, 10),
            'source'     => fake()->randomElement(['manual','checkin','widget','journal']),
            'note'       => fake()->optional()->sentence(),
            'logged_at'  => fake()->dateTimeBetween('-30 days', 'now'),
        ];
    }
}