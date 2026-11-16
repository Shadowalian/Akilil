<?php

namespace Tests\Feature\Api\Live;

use App\Models\Earning;
use App\Models\Gift;
use App\Models\LiveStream;
use App\Models\User;
use Database\Seeders\CatalogSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\Support\BuildsWorld;
use Tests\TestCase;

class LiveStreamTest extends TestCase
{
    use BuildsWorld, RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(CatalogSeeder::class);
    }

    /** A spiritual guide who is on air right now. @return array{0:User, 1:int} */
    private function onAir(): array
    {
        $guide = $this->pro('spiritual-psychiatry');
        $id = $this->actingAs($guide)->postJson('/api/live-streams', ['title' => 'Evening reflection'])->assertCreated()->json('stream.id');
        $this->actingAs($guide)->postJson("/api/live-streams/{$id}/start")->assertOk();

        return [$guide, $id];
    }

    /* ---- Who may broadcast ---- */

    public function test_a_spiritual_guide_goes_live_and_viewers_get_a_receive_only_room(): void
    {
        [$guide, $id] = $this->onAir();

        $host = $this->actingAs($guide)->postJson("/api/live-streams/{$id}/start")->assertOk()->json('session');
        $this->assertSame('broadcast_host', $host['mode']);
        $this->assertTrue($host['can_publish']);
        $this->assertStringContainsString('akilil-live-', $host['room_name']);

        $viewer = $this->adult();
        $view = $this->actingAs($viewer)->postJson("/api/live-streams/{$id}/join")
            ->assertOk()->assertJsonPath('can_send_gifts', true)->json('session');
        $this->assertSame('broadcast_view', $view['mode']);
        $this->assertFalse($view['can_publish']);
        $this->assertFalse($view['is_host']);
        $this->assertSame($host['room_name'], $view['room_name']);
        // No mic / camera buttons, and no camera prompt, for the audience.
        $this->assertStringContainsString('config.toolbarButtons=%5B%5D', $view['room_url']);
        $this->assertStringContainsString('config.disableInitialGUM=true', $view['room_url']);

        $this->actingAs($viewer)->getJson('/api/live-streams')->assertOk()
            ->assertJsonPath('data.0.status', 'live')->assertJsonPath('data.0.viewer_count', 1);
    }

    public function test_clinical_psychiatry_cannot_broadcast(): void
    {
        $this->actingAs($this->pro('psychiatry'))->postJson('/api/live-streams', ['title' => 'Open clinic'])->assertForbidden();
        $this->actingAs($this->adult())->postJson('/api/live-streams', ['title' => 'Me too'])->assertForbidden();
    }

    public function test_an_unverified_professional_cannot_go_live(): void
    {
        $guide = $this->pro('spiritual-psychiatry', ['verification_status' => 'pending']);
        $this->actingAs($guide)->postJson('/api/live-streams', ['title' => 'Too soon'])->assertForbidden();
    }

    public function test_a_chef_must_announce_a_live_cook_along_with_its_recipe_in_advance(): void
    {
        $chef = $this->pro('cooking');
        $recipe = $this->recipe($chef);

        $this->actingAs($chef)->postJson('/api/live-streams', ['title' => 'Cook with me', 'scheduled_at' => $this->slot()])
            ->assertStatus(422)->assertJsonValidationErrors('recipe_id');
        // "Go live now" leaves nobody time to shop.
        $this->actingAs($chef)->postJson('/api/live-streams', ['title' => 'Cook with me', 'recipe_id' => $recipe->id])
            ->assertStatus(422)->assertJsonValidationErrors('scheduled_at');

        $id = $this->actingAs($chef)->postJson('/api/live-streams', [
            'title' => 'Cook with me', 'recipe_id' => $recipe->id, 'scheduled_at' => $this->slot(),
        ])->assertCreated()->assertJsonPath('stream.recipe.title', 'Shiro wot')->assertJsonPath('stream.requires_ingredients', true)->json('stream.id');

        // Announced streams are discoverable with their recipe, but can't start days early.
        $this->actingAs($this->adult())->getJson('/api/live-streams?category=cooking')
            ->assertOk()->assertJsonPath('data.0.status', 'scheduled')->assertJsonPath('data.0.recipe.id', $recipe->id);
        $this->actingAs($chef)->postJson("/api/live-streams/{$id}/start")->assertStatus(422);

        LiveStream::whereKey($id)->update(['scheduled_at' => now()->addMinutes(5)]);
        $this->actingAs($chef)->postJson("/api/live-streams/{$id}/start")->assertOk();
    }

    /* ---- Audience ---- */

    public function test_viewers_must_join_before_they_can_comment_and_the_feed_is_cursor_based(): void
    {
        [$guide, $id] = $this->onAir();
        $viewer = $this->adult();

        $this->actingAs($viewer)->postJson("/api/live-streams/{$id}/comments", ['body' => 'Selam!'])->assertForbidden();
        $this->actingAs($viewer)->postJson("/api/live-streams/{$id}/join")->assertOk();
        $this->actingAs($viewer)->postJson("/api/live-streams/{$id}/comments", ['body' => 'Selam!'])->assertCreated();
        $this->actingAs($viewer)->postJson("/api/live-streams/{$id}/likes", ['count' => 7])->assertOk()->assertJsonPath('likes_count', 7);

        $first = $this->actingAs($guide)->getJson("/api/live-streams/{$id}/events")->assertOk()
            ->assertJsonPath('state.status', 'live')->assertJsonPath('state.viewer_count', 1)->assertJsonPath('state.likes_count', 7)
            ->json();
        $this->assertSame(['system', 'join', 'comment', 'like'], array_column($first['events'], 'type'));
        $this->assertSame('Selam!', $first['events'][2]['body']);

        // Nothing new since the cursor…
        $this->actingAs($guide)->getJson("/api/live-streams/{$id}/events?after={$first['cursor']}")->assertOk()->assertJsonCount(0, 'events');
        // …until something happens.
        $this->actingAs($viewer)->postJson("/api/live-streams/{$id}/comments", ['body' => 'Amen'])->assertCreated();
        $this->actingAs($guide)->getJson("/api/live-streams/{$id}/events?after={$first['cursor']}")
            ->assertOk()->assertJsonCount(1, 'events')->assertJsonPath('events.0.body', 'Amen');
    }

    public function test_the_host_moderates_comments_and_can_remove_a_viewer(): void
    {
        [$guide, $id] = $this->onAir();
        $troll = $this->adult();
        $this->actingAs($troll)->postJson("/api/live-streams/{$id}/join")->assertOk();
        $eventId = $this->actingAs($troll)->postJson("/api/live-streams/{$id}/comments", ['body' => 'spam'])->json('event.id');

        $this->actingAs($this->adult())->deleteJson("/api/live-stream-events/{$eventId}")->assertForbidden();
        $this->actingAs($guide)->deleteJson("/api/live-stream-events/{$eventId}")->assertOk();
        $bodies = array_column($this->actingAs($guide)->getJson("/api/live-streams/{$id}/events")->json('events'), 'body');
        $this->assertNotContains('spam', $bodies);

        $this->actingAs($guide)->postJson("/api/live-streams/{$id}/viewers/{$troll->id}/ban")->assertOk();
        $this->actingAs($troll)->postJson("/api/live-streams/{$id}/comments", ['body' => 'back'])->assertForbidden();
        $this->actingAs($troll)->postJson("/api/live-streams/{$id}/join")->assertForbidden();
        $this->actingAs($troll)->getJson("/api/live-streams/{$id}/events")->assertForbidden()->assertJsonPath('code', 'removed');

        // The host can also turn comments off for everyone.
        $this->actingAs($guide)->putJson("/api/live-streams/{$id}", ['allow_comments' => false])->assertOk();
        $fan = $this->adult();
        $this->actingAs($fan)->postJson("/api/live-streams/{$id}/join")->assertOk();
        $this->actingAs($fan)->postJson("/api/live-streams/{$id}/comments", ['body' => 'hi'])->assertStatus(422);
    }

    public function test_young_children_cannot_watch_and_nobody_joins_after_it_ends(): void
    {
        [$guide, $id] = $this->onAir();
        $kid = User::factory()->create(['role' => 'user', 'date_of_birth' => now()->subYears(10)]);
        $this->actingAs($kid)->postJson("/api/live-streams/{$id}/join")->assertForbidden()->assertJsonPath('code', 'age_restricted');

        $this->actingAs($this->adult())->postJson("/api/live-streams/{$id}/end")->assertForbidden();
        $this->actingAs($guide)->postJson("/api/live-streams/{$id}/end")->assertOk()->assertJsonPath('stream.status', 'ended');
        $this->actingAs($this->adult())->postJson("/api/live-streams/{$id}/join")->assertStatus(422);
    }

    /* ---- Gifts ---- */

    public function test_a_gift_moves_money_from_the_viewer_to_the_host_net_of_the_platform_fee(): void
    {
        [$guide, $id] = $this->onAir();
        $fan = $this->adult(5_000);
        $this->actingAs($fan)->postJson("/api/live-streams/{$id}/join")->assertOk();

        $catalogue = $this->actingAs($fan)->getJson('/api/gifts')->assertOk()->json('data');
        $this->assertGreaterThanOrEqual(5, count($catalogue));
        $rose = Gift::where('slug', 'rose')->firstOrFail();   // 200 each

        $this->actingAs($fan)->postJson("/api/live-streams/{$id}/gifts", ['gift_id' => $rose->id, 'quantity' => 3])
            ->assertCreated()
            ->assertJsonPath('spent_cents', 600)
            ->assertJsonPath('balance_cents', 4_400)
            ->assertJsonPath('event.type', 'gift')
            ->assertJsonPath('event.payload.gift.emoji', '🌹')
            ->assertJsonPath('event.payload.quantity', 3);

        $this->assertSame(4_400, $fan->wallet->fresh()->balance_cents);
        $earning = Earning::where('professional_user_id', $guide->id)->firstOrFail();
        $this->assertSame(['gift', 600, 180, 420], [$earning->kind, $earning->gross_cents, $earning->fee_cents, $earning->net_cents]);
        $this->assertDatabaseHas('transactions', ['user_id' => $fan->id, 'type' => 'gift', 'amount_cents' => 600]);

        // Everyone sees the gift in the feed; only the host sees the takings.
        $this->actingAs($fan)->getJson("/api/live-streams/{$id}/events")->assertJsonPath('state.gifts_total_cents', null);
        $this->actingAs($guide)->getJson("/api/live-streams/{$id}/events")->assertJsonPath('state.gifts_total_cents', 600);
        $this->actingAs($guide)->getJson('/api/professional/earnings/summary')
            ->assertJsonPath('by_source.gifts', 420)->assertJsonPath('available_cents', 420);
    }

    public function test_a_gift_the_viewer_cannot_afford_charges_nothing(): void
    {
        [$guide, $id] = $this->onAir();
        $fan = $this->adult(150);
        $this->actingAs($fan)->postJson("/api/live-streams/{$id}/join")->assertOk();

        $this->actingAs($fan)->postJson("/api/live-streams/{$id}/gifts", ['gift_slug' => 'crown'])
            ->assertStatus(402)->assertJsonPath('code', 'insufficient_balance')->assertJsonPath('required_cents', 5000);
        $this->assertSame(150, $fan->wallet->fresh()->balance_cents);
        $this->assertSame(0, Earning::count());
    }

    public function test_minors_can_watch_but_cannot_send_gifts(): void
    {
        [$guide, $id] = $this->onAir();
        $teen = User::factory()->create(['role' => 'user', 'date_of_birth' => now()->subYears(16), 'guardian_user_id' => $this->adult()->id]);
        \App\Models\Wallet::create(['user_id' => $teen->id, 'currency' => 'USD', 'balance_cents' => 9_999]);

        $this->actingAs($teen)->postJson("/api/live-streams/{$id}/join")->assertOk()->assertJsonPath('can_send_gifts', false);
        $this->actingAs($teen)->postJson("/api/live-streams/{$id}/gifts", ['gift_slug' => 'rose'])
            ->assertForbidden()->assertJsonPath('code', 'guardian_required');
        $this->assertSame(9_999, $teen->wallet->fresh()->balance_cents);
    }

    public function test_hosts_cannot_gift_themselves_and_gifts_can_be_switched_off(): void
    {
        [$guide, $id] = $this->onAir();
        \App\Models\Wallet::create(['user_id' => $guide->id, 'currency' => 'USD', 'balance_cents' => 9_999]);
        $this->actingAs($guide)->postJson("/api/live-streams/{$id}/gifts", ['gift_slug' => 'rose'])->assertStatus(422);

        $this->actingAs($guide)->putJson("/api/live-streams/{$id}", ['allow_gifts' => false])->assertOk();
        $fan = $this->adult();
        $this->actingAs($fan)->postJson("/api/live-streams/{$id}/join")->assertOk()->assertJsonPath('can_send_gifts', false);
        $this->actingAs($fan)->postJson("/api/live-streams/{$id}/gifts", ['gift_slug' => 'rose'])->assertStatus(422);
    }
}
