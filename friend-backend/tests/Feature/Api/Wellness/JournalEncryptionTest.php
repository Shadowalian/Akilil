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
}
