<?php

namespace App\Services;

use App\Models\Appointment;
use App\Models\LiveStream;
use App\Models\Recipe;
use App\Models\TherapyGroupMeeting;
use App\Models\User;
use Carbon\CarbonInterface;
use Illuminate\Validation\ValidationException;

/**
 * "Ingredients before the session" — the rules every cooking surface
 * (1:1 class, group class, live stream) shares:
 *
 *   1. it must name one of the chef's own published recipes, and
 *   2. it must be scheduled far enough ahead for people to shop.
 */
class CookingRules
{
    /** A published recipe of this chef with at least one ingredient, or a 422. */
    public function requireRecipe(User $chef, mixed $recipeId, string $field = 'recipe_id'): Recipe
    {
        if (! $recipeId) {
            throw ValidationException::withMessages([
                $field => ['Cooking sessions need a recipe so everyone can get the ingredients beforehand.'],
            ]);
        }

        $recipe = Recipe::withCount('ingredients')
            ->where('professional_user_id', $chef->id)
            ->find($recipeId);

        if (! $recipe || ! $recipe->isPublished()) {
            throw ValidationException::withMessages([$field => ['Pick one of the chef\'s published recipes.']]);
        }
        if ($recipe->ingredients_count < 1) {
            throw ValidationException::withMessages([$field => ['This recipe has no ingredient list yet.']]);
        }

        return $recipe;
    }

    /** The start time must leave shopping time. */
    public function requireLeadTime(CarbonInterface $startsAt, string $field = 'scheduled_at'): void
    {
        $hours = $this->leadHours();
        if ($startsAt->lt(now()->addHours($hours))) {
            throw ValidationException::withMessages([
                $field => ["Cooking sessions must be scheduled at least {$hours} hours ahead so participants can buy the ingredients."],
            ]);
        }
    }

    public function leadHours(): int
    {
        return (int) config('akilil.cooking.min_lead_hours', 24);
    }

    /** Chefs can open the room a little early, not hours before people expect it. */
    public function requireNotTooEarly(CarbonInterface $scheduledAt): void
    {
        $early = (int) config('akilil.cooking.early_start_minutes', 15);
        if (now()->lt($scheduledAt->copy()->subMinutes($early))) {
            throw ValidationException::withMessages([
                'scheduled_at' => ["This cooking session opens {$early} minutes before its scheduled time."],
            ]);
        }
    }

    /**
     * True when a session using this recipe starts inside the shopping
     * window — people may already have bought the ingredients, so the
     * list must not change under them.
     */
    public function recipeIsLocked(Recipe $recipe): bool
    {
        $from = now()->subHours(6);
        $until = now()->addHours($this->leadHours());

        return Appointment::where('recipe_id', $recipe->id)
                ->whereIn('status', ['pending', 'confirmed', 'in_progress'])
                ->whereBetween('scheduled_at', [$from, $until])->exists()
            || TherapyGroupMeeting::where('recipe_id', $recipe->id)
                ->whereIn('status', ['scheduled', 'live'])
                ->whereBetween('scheduled_at', [$from, $until])->exists()
            || LiveStream::where('recipe_id', $recipe->id)
                ->whereIn('status', ['scheduled', 'live'])
                ->whereBetween('scheduled_at', [$from, $until])->exists();
    }

    /** Any not-yet-finished session still points at this recipe. */
    public function recipeInUse(Recipe $recipe): bool
    {
        return Appointment::where('recipe_id', $recipe->id)
                ->whereIn('status', ['pending', 'confirmed', 'in_progress'])->exists()
            || TherapyGroupMeeting::where('recipe_id', $recipe->id)
                ->whereIn('status', ['scheduled', 'live'])->exists()
            || LiveStream::where('recipe_id', $recipe->id)
                ->whereIn('status', ['scheduled', 'live'])->exists();
    }
}
