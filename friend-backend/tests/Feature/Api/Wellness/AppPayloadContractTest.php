<?php

namespace Tests\Feature\Api\Wellness;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * The exact bodies the client app sends. These broke silently once (the app
 * sent `mood` and `body_md` while the API expected `mood_score` and
 * `content`), so they are pinned here.
 */
class AppPayloadContractTest extends TestCase
{
    use RefreshDatabase;

    public function test_a_mood_check_in_from_the_app_is_saved(): void
    {
        $user = User::factory()->create();
        $this->actingAs($user)->postJson('/api/mood-logs', ['mood_score' => 5, 'note' => 'Slept well'])
            ->assertSuccessful();
        $this->assertDatabaseHas('mood_logs', ['user_id' => $user->id, 'mood_score' => 5]);
    }

    public function test_the_old_mood_field_name_is_rejected(): void
    {
        $this->actingAs(User::factory()->create())
            ->postJson('/api/mood-logs', ['mood' => 5])
            ->assertStatus(422)
            ->assertJsonValidationErrors('mood_score');
    }
}
