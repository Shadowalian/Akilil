<?php

namespace Tests\Feature\Api\Messaging;

use App\Models\Conversation;
use App\Models\ConversationParticipant;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class MessagingTest extends TestCase
{
    use RefreshDatabase;

    protected User $alice;
    protected User $bob;
    protected Conversation $direct;

    protected function setUp(): void
    {
        parent::setUp();
        $this->alice = User::factory()->create(['role' => 'user', 'name' => 'Alice']);
        $this->bob   = User::factory()->create(['role' => 'user', 'name' => 'Bob']);

        $this->direct = Conversation::create(['type' => 'direct', 'created_by' => $this->alice->id]);
        ConversationParticipant::create(['conversation_id' => $this->direct->id, 'user_id' => $this->alice->id, 'joined_at' => now()]);
        ConversationParticipant::create(['conversation_id' => $this->direct->id, 'user_id' => $this->bob->id, 'joined_at' => now()]);
    }

    public function test_user_can_list_their_conversations(): void
    {
        $token = $this->alice->createToken('test')->plainTextToken;
        $res = $this->withToken($token)->getJson('/api/conversations');
        $res->assertOk()->assertJsonStructure(['data' => [], 'meta' => []]);
        $this->assertCount(1, $res->json('data'));
    }

    public function test_user_can_send_a_text_message(): void
    {
        $token = $this->alice->createToken('test')->plainTextToken;
        $res = $this->withToken($token)
            ->postJson("/api/conversations/{$this->direct->id}/messages", [
                'message_type' => 'text',
                'content'      => 'Hi Bob',
            ]);
        $res->assertCreated()
            ->assertJsonStructure(['id', 'conversation_id', 'message_type', 'content_encrypted', 'created_at']);
        $this->assertDatabaseHas('conversations', ['id' => $this->direct->id]);
    }

    public function test_non_participant_cannot_send_message(): void
    {
        $eve = User::factory()->create(['role' => 'user']);
        $token = $eve->createToken('test')->plainTextToken;
        $this->withToken($token)
            ->postJson("/api/conversations/{$this->direct->id}/messages", [
                'message_type' => 'text', 'content' => 'sneaky',
            ])
            ->assertForbidden();
    }

    public function test_message_history_returns_in_descending_order(): void
    {
        $token = $this->alice->createToken('test')->plainTextToken;
        // Send 3 messages
        for ($i = 1; $i <= 3; $i++) {
            $this->withToken($token)->postJson("/api/conversations/{$this->direct->id}/messages", [
                'message_type' => 'text', 'content' => "Message $i",
            ])->assertCreated();
        }
        $res = $this->withToken($token)->getJson("/api/conversations/{$this->direct->id}/messages");
        $res->assertOk();
        $data = $res->json('data');
        $this->assertCount(3, $data);
        // Most recent first
        $this->assertEquals('Message 3', $data[0]['content_encrypted']);
    }

    public function test_user_can_upload_voice_message(): void
    {
        Storage::fake(config('filesystems.private_disk', 'local'));

        $token = $this->alice->createToken('test')->plainTextToken;
        $file = UploadedFile::fake()->create('voice.m4a', 60, 'audio/mp4');

        $res = $this->withToken($token)->post("/api/conversations/{$this->direct->id}/messages", [
            'message_type'     => 'voice',
            'file'             => $file,
            'duration_seconds' => 12,
        ]);
        $res->assertCreated();
        $this->assertDatabaseHas('messages', [
            'conversation_id' => $this->direct->id,
            'message_type'    => 'voice',
            'media_duration_seconds' => 12,
        ]);
    }

    public function test_idempotent_direct_conversation_returns_existing(): void
    {
        $token = $this->alice->createToken('test')->plainTextToken;
        $res = $this->withToken($token)->postJson('/api/conversations', [
            'participant_user_id' => $this->bob->id,
        ]);
        $res->assertOk();
        $id1 = $res->json('id');

        $res2 = $this->withToken($token)->postJson('/api/conversations', [
            'participant_user_id' => $this->bob->id,
        ]);
        $res2->assertOk();
        $this->assertEquals($id1, $res2->json('id'));
    }
}