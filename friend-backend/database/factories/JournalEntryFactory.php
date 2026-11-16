<?php

namespace Database\Factories;

use App\Models\JournalEntry;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<JournalEntry>
 */
class JournalEntryFactory extends Factory
{
    protected $model = JournalEntry::class;

    public function definition(): array
    {
        return [
            'user_id'      => User::factory(),
            'mood_score'   => fake()->numberBetween(2, 9),
            'mood_tags'    => fake()->randomElements(['anxious','tired','focused','grateful','overwhelmed'], 2),
            'content'      => fake()->paragraph(3),
            'is_private'   => true,
            'created_client_at' => now()->subMinutes(fake()->numberBetween(0, 1440)),
        ];
    }
}