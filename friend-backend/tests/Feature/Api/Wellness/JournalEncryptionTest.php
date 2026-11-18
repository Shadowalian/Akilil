<?php

namespace Tests\Feature\Api\Wellness;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class JournalEncryptionTest extends TestCase
{
    use RefreshDatabase;

    public function test_journal_text_is_not_stored_in_plain_text(): void
    {
        $user = User::factory()->create();
        $id = $this->actingAs($user)->postJson('/api/journal-entries', ['content' => 'Something private', 'mood_score' => 4])
            ->assertCreated()->json('id') ?? $this->actingAs($user)->getJson('/api/journal-entries')->json('data.0.id');

        $raw = DB::table('journal_entries')->value('content');
        $this->assertStringNotContainsString('Something private', $raw);
        $this->actingAs($user)->getJson('/api/journal-entries')->assertJsonFragment(['content' => 'Something private']);
    }

    /** The exact payload the client app sends: title, content and a 1–7 mood. */
    public function test_an_entry_from_the_app_round_trips_with_its_title_encrypted(): void
    {
        $user = User::factory()->create();
        $this->actingAs($user)->postJson('/api/journal-entries', [
            'title' => 'Sunday',
            'content' => 'A quiet day.',
            'mood_score' => 6,
        ])->assertCreated();

        $this->assertStringNotContainsString('Sunday', (string) DB::table('journal_entries')->value('title'));
        $this->actingAs($user)->getJson('/api/journal-entries')
            ->assertJsonPath('data.0.title', 'Sunday')
            ->assertJsonPath('data.0.content', 'A quiet day.')
            ->assertJsonPath('data.0.mood_score', 6);
    }

    public function test_an_entry_without_text_is_rejected_with_a_clear_message(): void
    {
        $this->actingAs(User::factory()->create())
            ->postJson('/api/journal-entries', ['title' => 'Only a title'])
            ->assertStatus(422)
            ->assertJsonValidationErrors('content');
    }
}
