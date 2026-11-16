<?php

namespace Tests\Support;

use App\Models\Category;
use App\Models\ProfessionalProfile;
use App\Models\Recipe;
use App\Models\User;
use App\Models\Wallet;
use Carbon\CarbonImmutable;

/** Small builders shared by the family / cooking / live feature tests. */
trait BuildsWorld
{
    protected function adult(int $balanceCents = 1_000_000, array $attrs = []): User
    {
        $user = User::factory()->create(['role' => 'user', 'date_of_birth' => '1990-01-01', ...$attrs]);
        Wallet::create(['user_id' => $user->id, 'currency' => 'USD', 'balance_cents' => $balanceCents]);

        return $user;
    }

    /** An approved professional in a pillar, available every day 00:00–23:59 UTC. */
    protected function pro(string $pillar = 'psychiatry', array $profile = []): User
    {
        $category = Category::firstOrCreate(['slug' => $pillar], ['name' => ucfirst($pillar), 'is_active' => true]);
        $pro = User::factory()->create(['role' => 'professional', 'date_of_birth' => '1980-01-01']);
        ProfessionalProfile::factory()->approved()->create([
            'user_id' => $pro->id,
            'category_id' => $category->id,
            'verification_status' => 'approved',
            'is_accepting_clients' => true,
            'hourly_rate_cents' => 5000,
            'currency' => 'USD',
            'session_duration_minutes' => 45,
            ...$profile,
        ]);
        foreach (range(1, 7) as $weekday) {
            $pro->availabilitySlotRules()->create([
                'weekday' => $weekday, 'start_time' => '00:00:00', 'end_time' => '23:59:00',
                'slot_duration_minutes' => 45, 'buffer_minutes' => 0, 'timezone' => 'UTC', 'is_active' => true,
            ]);
        }

        return $pro;
    }

    protected function recipe(User $chef, bool $published = true): Recipe
    {
        $recipe = Recipe::create([
            'professional_user_id' => $chef->id,
            'title' => 'Shiro wot',
            'status' => $published ? 'published' : 'draft',
            'published_at' => $published ? now() : null,
        ]);
        $recipe->ingredients()->create(['name' => 'Shiro powder', 'quantity' => '1', 'unit' => 'cup']);
        $recipe->ingredients()->create(['name' => 'Red onion', 'quantity' => '2']);
        $recipe->ingredients()->create(['name' => 'Jalapeño', 'is_optional' => true]);
        $recipe->steps()->create(['position' => 1, 'instruction' => 'Cook the onions down.']);

        return $recipe;
    }

    /** A whole-hour UTC instant N days out — always inside the pro's rules. */
    protected function slot(int $daysAhead = 3, int $hour = 10): string
    {
        return CarbonImmutable::now('UTC')->addDays($daysAhead)->setTime($hour, 0)->toIso8601String();
    }
}
