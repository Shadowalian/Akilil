<?php

namespace Tests\Feature\Api\Cooking;

use App\Models\Appointment;
use App\Models\Earning;
use App\Models\TherapyGroup;
use App\Models\TherapyGroupMeeting;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\Support\BuildsWorld;
use Tests\TestCase;

class CookingTest extends TestCase
{
    use BuildsWorld, RefreshDatabase;

    private function recipePayload(array $overrides = []): array
    {
        return [
            'title' => 'Doro wot', 'cuisine' => 'Ethiopian', 'difficulty' => 'medium', 'servings' => 4,
            'ingredients' => [
                ['name' => 'Chicken', 'quantity' => '1', 'unit' => 'kg'],
                ['name' => 'Berbere', 'quantity' => '3', 'unit' => 'tbsp', 'substitute' => 'Paprika + chili'],
                ['name' => 'Boiled eggs', 'quantity' => '4', 'is_optional' => true],
            ],
            'steps' => [['instruction' => 'Slow-cook the onions.', 'duration_minutes' => 40]],
            ...$overrides,
        ];
    }

    /* ---- Recipes ---- */

    public function test_chef_writes_and_publishes_a_recipe(): void
    {
        $chef = $this->pro('cooking');

        $id = $this->actingAs($chef)->postJson('/api/recipes', $this->recipePayload())
            ->assertCreated()
            ->assertJsonPath('recipe.status', 'draft')
            ->assertJsonCount(3, 'recipe.ingredients')
            ->json('recipe.id');

        // Drafts are invisible to clients.
        $client = $this->adult();
        $this->actingAs($client)->getJson("/api/recipes/{$id}")->assertNotFound();

        $this->actingAs($chef)->postJson("/api/recipes/{$id}/publish")->assertOk()->assertJsonPath('recipe.status', 'published');
        $this->actingAs($client)->getJson("/api/recipes/{$id}")->assertOk()->assertJsonPath('recipe.ingredients.1.substitute', 'Paprika + chili');
        $this->actingAs($client)->getJson("/api/recipes?professional_user_id={$chef->id}")->assertOk()->assertJsonCount(1, 'data');
    }

    public function test_a_recipe_without_ingredients_cannot_be_published(): void
    {
        $chef = $this->pro('cooking');
        $id = $this->actingAs($chef)->postJson('/api/recipes', ['title' => 'Empty'])->assertCreated()->json('recipe.id');

        $this->actingAs($chef)->postJson("/api/recipes/{$id}/publish")->assertStatus(422)->assertJsonValidationErrors('ingredients');
    }

    public function test_only_chefs_manage_recipes_and_only_their_own(): void
    {
        $this->actingAs($this->pro('psychiatry'))->postJson('/api/recipes', $this->recipePayload())->assertForbidden();
        $this->actingAs($this->adult())->postJson('/api/recipes', $this->recipePayload())->assertForbidden();

        $recipe = $this->recipe($this->pro('cooking'));
        $this->actingAs($this->pro('cooking'))->putJson("/api/recipes/{$recipe->id}", ['title' => 'Mine now'])->assertNotFound();
    }

    public function test_shopping_checklist_tracks_what_is_still_missing(): void
    {
        $recipe = $this->recipe($this->pro('cooking'));
        $client = $this->adult();
        [$shiro, $onion, $optional] = $recipe->ingredients->pluck('id')->all();

        $this->actingAs($client)->getJson("/api/recipes/{$recipe->id}/checklist")
            ->assertOk()->assertJsonPath('is_complete', false)->assertJsonCount(2, 'missing_required_ids');

        $this->actingAs($client)->putJson("/api/recipes/{$recipe->id}/checklist", ['checked_ingredient_ids' => [$shiro, 999]])
            ->assertOk()->assertJsonPath('missing_required_ids', [$onion])->assertJsonPath('checked_ingredient_ids', [$shiro]);

        // Optional items don't block "complete".
        $this->actingAs($client)->putJson("/api/recipes/{$recipe->id}/checklist", ['checked_ingredient_ids' => [$shiro, $onion]])
            ->assertOk()->assertJsonPath('is_complete', true);
    }

    /* ---- 1:1 cooking sessions ---- */

    public function test_booking_a_chef_requires_one_of_their_published_recipes(): void
    {
        $chef = $this->pro('cooking');
        $client = $this->adult();
        $base = ['professional_user_id' => $chef->id, 'scheduled_at' => $this->slot()];

        $this->actingAs($client)->postJson('/api/appointments', $base)
            ->assertStatus(422)->assertJsonValidationErrors('recipe_id');

        $draft = $this->recipe($chef, published: false);
        $this->actingAs($client)->postJson('/api/appointments', [...$base, 'recipe_id' => $draft->id])
            ->assertStatus(422)->assertJsonValidationErrors('recipe_id');

        $someoneElses = $this->recipe($this->pro('cooking'));
        $this->actingAs($client)->postJson('/api/appointments', [...$base, 'recipe_id' => $someoneElses->id])
            ->assertStatus(422)->assertJsonValidationErrors('recipe_id');

        $recipe = $this->recipe($chef);
        $this->actingAs($client)->postJson('/api/appointments', [...$base, 'recipe_id' => $recipe->id])
            ->assertCreated()
            ->assertJsonPath('recipe.title', 'Shiro wot')
            ->assertJsonPath('requires_ingredients', true)
            ->assertJsonPath('ingredients_confirmed_at', null);
    }

    public function test_cooking_sessions_must_leave_time_to_shop(): void
    {
        $chef = $this->pro('cooking');
        $recipe = $this->recipe($chef);

        $this->actingAs($this->adult())->postJson('/api/appointments', [
            'professional_user_id' => $chef->id, 'recipe_id' => $recipe->id,
            'scheduled_at' => now('UTC')->addHours(5)->startOfHour()->toIso8601String(),
        ])->assertStatus(422)->assertJsonValidationErrors('scheduled_at');
    }

    public function test_the_client_confirms_ingredients_before_joining_the_kitchen(): void
    {
        $chef = $this->pro('cooking');
        $recipe = $this->recipe($chef);
        $client = $this->adult();
        $id = $this->actingAs($client)->postJson('/api/appointments', [
            'professional_user_id' => $chef->id, 'recipe_id' => $recipe->id, 'scheduled_at' => $this->slot(),
        ])->assertCreated()->json('id');

        // Too early: the kitchen opens 15 minutes before.
        $this->actingAs($chef)->postJson("/api/appointments/{$id}/session/start")->assertStatus(422);

        Appointment::whereKey($id)->update(['scheduled_at' => now()->addMinutes(5)]);
        $this->actingAs($chef)->postJson("/api/appointments/{$id}/session/start")->assertOk();

        $this->actingAs($client)->postJson("/api/appointments/{$id}/session/start")
            ->assertStatus(422)->assertJsonPath('code', 'ingredients_required')->assertJsonPath('recipe_id', $recipe->id);

        $this->actingAs($client)->postJson("/api/appointments/{$id}/ingredients/confirm")->assertOk();
        $this->actingAs($client)->postJson("/api/appointments/{$id}/session/start")->assertOk();
    }

    public function test_ingredients_are_locked_once_people_are_shopping(): void
    {
        $chef = $this->pro('cooking');
        $recipe = $this->recipe($chef);
        $id = $this->actingAs($this->adult())->postJson('/api/appointments', [
            'professional_user_id' => $chef->id, 'recipe_id' => $recipe->id, 'scheduled_at' => $this->slot(),
        ])->json('id');

        // Three days out: still editable.
        $this->actingAs($chef)->putJson("/api/recipes/{$recipe->id}", ['ingredients' => [['name' => 'Shiro powder'], ['name' => 'Garlic']]])->assertOk();

        Appointment::whereKey($id)->update(['scheduled_at' => now()->addHours(6)]);
        $this->actingAs($chef)->putJson("/api/recipes/{$recipe->id}", ['ingredients' => [['name' => 'Surprise truffle']]])
            ->assertStatus(422)->assertJsonValidationErrors('ingredients');
        $this->actingAs($chef)->putJson("/api/recipes/{$recipe->id}", ['description' => 'Typo fixed'])->assertOk();
        $this->actingAs($chef)->deleteJson("/api/recipes/{$recipe->id}")->assertStatus(422);
    }

    /* ---- Group classes ---- */

    private function cookingClass(User $chef, int $priceCents = 2000, int $max = 12): TherapyGroup
    {
        $id = $this->actingAs($chef)->postJson('/api/therapy-groups', [
            'title' => 'Sunday kitchen', 'price_cents' => $priceCents, 'max_members' => $max,
        ])->assertCreated()->assertJsonPath('group.is_cooking_class', true)->json('group.id');

        return TherapyGroup::findOrFail($id);
    }

    public function test_a_cooking_class_needs_a_recipe_and_lead_time(): void
    {
        $chef = $this->pro('cooking');
        $group = $this->cookingClass($chef);
        $recipe = $this->recipe($chef);

        $this->actingAs($chef)->postJson("/api/therapy-groups/{$group->id}/meetings", ['scheduled_at' => $this->slot()])
            ->assertStatus(422)->assertJsonValidationErrors('recipe_id');
        $this->actingAs($chef)->postJson("/api/therapy-groups/{$group->id}/meetings", [
            'scheduled_at' => now()->addHours(3)->toIso8601String(), 'recipe_id' => $recipe->id,
        ])->assertStatus(422)->assertJsonValidationErrors('scheduled_at');

        $this->actingAs($chef)->postJson("/api/therapy-groups/{$group->id}/meetings", ['scheduled_at' => $this->slot(), 'recipe_id' => $recipe->id])
            ->assertCreated()->assertJsonPath('meeting.recipe.title', 'Shiro wot')->assertJsonPath('meeting.price_cents', 2000);
    }

    public function test_group_class_seats_are_paid_gated_on_ingredients_and_pay_the_chef(): void
    {
        $chef = $this->pro('cooking');
        $group = $this->cookingClass($chef, priceCents: 2000);
        $recipe = $this->recipe($chef);
        $meetingId = $this->actingAs($chef)->postJson("/api/therapy-groups/{$group->id}/meetings", [
            'scheduled_at' => $this->slot(), 'recipe_id' => $recipe->id,
        ])->json('meeting.id');

        $cook = $this->adult(5_000);
        $this->actingAs($cook)->postJson("/api/therapy-group-meetings/{$meetingId}/reserve")->assertForbidden();   // not a member yet
        $this->actingAs($cook)->postJson("/api/therapy-groups/{$group->id}/join")->assertOk();
        $this->actingAs($cook)->postJson("/api/therapy-group-meetings/{$meetingId}/reserve")
            ->assertCreated()->assertJsonPath('meeting.my_seat.status', 'reserved')->assertJsonPath('meeting.seats_taken', 1);
        $this->assertSame(3_000, $cook->wallet->fresh()->balance_cents);
        // Reserving twice doesn't charge twice.
        $this->actingAs($cook)->postJson("/api/therapy-group-meetings/{$meetingId}/reserve")->assertOk();
        $this->assertSame(3_000, $cook->wallet->fresh()->balance_cents);

        // Chef opens the kitchen at the scheduled time.
        TherapyGroupMeeting::whereKey($meetingId)->update(['scheduled_at' => now()->addMinutes(5)]);
        $this->actingAs($chef)->postJson("/api/therapy-group-meetings/{$meetingId}/start")
            ->assertOk()->assertJsonPath('session.mode', 'group')->assertJsonPath('session.is_host', true);

        // A member without a seat is asked to pay; one with a seat must confirm ingredients.
        $late = $this->adult(0);
        $this->actingAs($late)->postJson("/api/therapy-groups/{$group->id}/join")->assertOk();
        $this->actingAs($late)->postJson("/api/therapy-group-meetings/{$meetingId}/join")->assertStatus(402)->assertJsonPath('code', 'seat_required');

        $this->actingAs($cook)->postJson("/api/therapy-group-meetings/{$meetingId}/join")
            ->assertStatus(422)->assertJsonPath('code', 'ingredients_required');
        $this->actingAs($cook)->postJson("/api/therapy-group-meetings/{$meetingId}/ingredients/confirm")->assertOk();
        $this->actingAs($cook)->postJson("/api/therapy-group-meetings/{$meetingId}/join")
            ->assertOk()->assertJsonPath('session.is_host', false);

        $this->actingAs($chef)->postJson("/api/therapy-group-meetings/{$meetingId}/end")->assertOk();
        $earning = Earning::where('professional_user_id', $chef->id)->firstOrFail();
        $this->assertSame(['group_seat', 2000, 1600], [$earning->kind, $earning->gross_cents, $earning->net_cents]);
    }

    public function test_a_full_class_sells_no_more_seats_and_a_cancelled_class_refunds_everyone(): void
    {
        $chef = $this->pro('cooking');
        $group = $this->cookingClass($chef, priceCents: 2000, max: 2);
        $meetingId = $this->actingAs($chef)->postJson("/api/therapy-groups/{$group->id}/meetings", [
            'scheduled_at' => $this->slot(), 'recipe_id' => $this->recipe($chef)->id,
        ])->json('meeting.id');

        $a = $this->adult(5_000);
        $b = $this->adult(5_000);
        foreach ([$a, $b] as $u) {
            $this->actingAs($u)->postJson("/api/therapy-groups/{$group->id}/join")->assertOk();
            $this->actingAs($u)->postJson("/api/therapy-group-meetings/{$meetingId}/reserve")->assertCreated();
        }
        $c = $this->adult(5_000);
        // The class is capped at two.
        $this->actingAs($c)->postJson("/api/therapy-groups/{$group->id}/join")->assertStatus(422);
        $this->actingAs($c)->postJson("/api/therapy-group-meetings/{$meetingId}/reserve")->assertForbidden();
        $this->assertSame(5_000, $c->wallet->fresh()->balance_cents);

        // A seat frees up when someone cancels (and, days ahead, is refunded).
        $this->actingAs($b)->postJson("/api/therapy-group-meetings/{$meetingId}/cancel-seat")->assertOk()->assertJsonPath('refunded_cents', 2000);
        $this->assertSame(5_000, $b->wallet->fresh()->balance_cents);

        $this->actingAs($chef)->postJson("/api/therapy-group-meetings/{$meetingId}/cancel")->assertOk();
        $this->assertSame(5_000, $a->wallet->fresh()->balance_cents);
        $this->assertSame(0, Earning::count());
    }

    public function test_group_therapy_is_adults_only_unless_the_host_says_otherwise(): void
    {
        $guide = $this->pro('spiritual-psychiatry');
        $id = $this->actingAs($guide)->postJson('/api/therapy-groups', ['title' => 'Grief circle'])
            ->assertCreated()->assertJsonPath('group.min_age', 18)->assertJsonPath('group.category.slug', 'spiritual-psychiatry')->json('group.id');

        $teen = User::factory()->create(['role' => 'user', 'date_of_birth' => now()->subYears(15), 'guardian_user_id' => $this->adult()->id]);
        $this->actingAs($teen)->postJson("/api/therapy-groups/{$id}/join")->assertForbidden()->assertJsonPath('code', 'age_restricted');

        // Free meetings seat members automatically; no recipe, no gate.
        $meetingId = $this->actingAs($guide)->postJson("/api/therapy-groups/{$id}/meetings", ['scheduled_at' => now()->addHour()->toIso8601String()])
            ->assertCreated()->json('meeting.id');
        $member = $this->adult(0);
        $this->actingAs($member)->postJson("/api/therapy-groups/{$id}/join")->assertOk();
        $this->actingAs($guide)->postJson("/api/therapy-group-meetings/{$meetingId}/start")->assertOk();
        $this->actingAs($member)->postJson("/api/therapy-group-meetings/{$meetingId}/join")->assertOk();
        $this->actingAs($this->adult())->postJson("/api/therapy-group-meetings/{$meetingId}/join")->assertForbidden();
    }
}
