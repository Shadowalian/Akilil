<?php

namespace Tests\Feature\Api\Wellness;

use App\Models\Habit;
use App\Models\HabitLog;
use App\Models\JournalEntry;
use App\Models\MoodLog;
use App\Models\User;
use App\Models\Vent;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class WellnessCrudTest extends TestCase
{
    use RefreshDatabase;

    public function test_journal_crud(): void
    {
        $user = User::factory()->create(['role' => 'user']);
        $token = $user->createToken('test')->plainTextToken;

        $create = $this->withToken($token)->postJson('/api/journal-entries', [
            'content'     => 'Today was hard.',
            'mood_score'  => 4,
            'mood_tags'   => ['tired', 'anxious'],
        ]);
        $create->assertCreated()->assertJsonStructure(['id', 'content', 'mood_score', 'mood_tags', 'created_at']);
        $id = $create->json('id');

        $this->withToken($token)->getJson("/api/journal-entries/{$id}")->assertOk();
        $this->withToken($token)->putJson("/api/journal-entries/{$id}", ['content' => 'Updated'])
            ->assertOk()->assertJson(['content' => 'Updated']);
        $this->withToken($token)->deleteJson("/api/journal-entries/{$id}")->assertOk();
    }

    public function test_journal_offline_client_uuid_is_idempotent(): void
    {
        $user = User::factory()->create(['role' => 'user']);
        $token = $user->createToken('test')->plainTextToken;

        $uuid = '11111111-1111-1111-1111-111111111111';
        $a = $this->withToken($token)->postJson('/api/journal-entries', [
            'content'     => 'a', 'client_uuid' => $uuid,
        ])->assertCreated()->json();
        $b = $this->withToken($token)->postJson('/api/journal-entries', [
            'content'     => 'a', 'client_uuid' => $uuid,
        ])->assertOk()->json();
        $this->assertEquals($a['id'], $b['id'], 'Idempotency on client_uuid broken.');
    }

    public function test_user_cannot_view_another_users_journal(): void
    {
        $alice = User::factory()->create(['role' => 'user']);
        $bob   = User::factory()->create(['role' => 'user']);
        $entry = JournalEntry::create(['user_id' => $alice->id, 'content' => 'private']);

        $token = $bob->createToken('test')->plainTextToken;
        $this->withToken($token)->getJson("/api/journal-entries/{$entry->id}")
            ->assertNotFound();
    }

    public function test_mood_log_store_and_analytics(): void
    {
        $user = User::factory()->create(['role' => 'user']);
        $token = $user->createToken('test')->plainTextToken;

        // Create mood logs across 3 days
        foreach ([1, 2, 3] as $daysAgo) {
            $this->withToken($token)->postJson('/api/mood-logs', [
                'mood_score' => 5 + $daysAgo,
                'logged_at'  => now()->subDays($daysAgo)->toIso8601String(),
            ])->assertCreated();
        }

        $res = $this->withToken($token)->getJson('/api/mood-logs/analytics?group_by=day');
        $res->assertOk()->assertJsonStructure(['group_by', 'series' => [['bucket', 'avg_score', 'samples']]]);
        $this->assertCount(3, $res->json('series'));
    }

    public function test_goal_crud(): void
    {
        $user = User::factory()->create(['role' => 'user']);
        $token = $user->createToken('test')->plainTextToken;

        $id = $this->withToken($token)->postJson('/api/goals', [
            'title' => 'Run 5k', 'target' => '5km in 30 min',
        ])->assertCreated()->json('id');

        $this->withToken($token)->putJson("/api/goals/{$id}", ['progress' => 50])->assertOk();
        $this->assertDatabaseHas('goals', ['id' => $id, 'progress' => 50]);
    }

    public function test_habit_create_and_log_idempotent(): void
    {
        $user = User::factory()->create(['role' => 'user']);
        $token = $user->createToken('test')->plainTextToken;

        $habit = $this->withToken($token)->postJson('/api/habits', [
            'title'   => 'Drink water',
            'cadence' => 'daily',
        ])->assertCreated()->json();

        // First log
        $r1 = $this->withToken($token)->postJson("/api/habits/{$habit['id']}/log", [
            'log_date' => '2026-07-09',
        ])->assertCreated();
        $this->assertDatabaseCount('habit_logs', 1);

        // Same date again — same row
        $this->withToken($token)->postJson("/api/habits/{$habit['id']}/log", [
            'log_date' => '2026-07-09',
        ])->assertCreated();
        $this->assertDatabaseCount('habit_logs', 1);
    }

    public function test_vent_text_create_with_expiry(): void
    {
        $user = User::factory()->create(['role' => 'user']);
        $token = $user->createToken('test')->plainTextToken;

        $res = $this->withToken($token)->postJson('/api/vents', [
            'content_type' => 'text',
            'content'      => 'just thinking out loud',
            'is_anonymous' => true,
            'expires_at'   => now()->addHour()->toIso8601String(),
        ]);
        $res->assertCreated()->assertJson(['is_anonymous' => true]);
        $this->assertDatabaseHas('vents', ['author_user_id' => $user->id, 'is_anonymous' => 1]);
    }

    public function test_vent_requires_text_or_voice(): void
    {
        $user = User::factory()->create(['role' => 'user']);
        $token = $user->createToken('test')->plainTextToken;

        $this->withToken($token)->postJson('/api/vents', [
            'content_type' => 'text',
        ])->assertJsonValidationErrors('content');
    }
}