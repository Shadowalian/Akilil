<?php

namespace Tests\Feature\Api\Community;

use App\Models\CommunityChannel;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class CommunityApiTest extends TestCase
{
    use RefreshDatabase;

    private User $user;
    private CommunityChannel $channel;

    protected function setUp(): void
    {
        parent::setUp();

        $this->user = User::factory()->create(['role' => 'user']);
        $this->channel = CommunityChannel::create([
            'created_by'   => $this->user->id,
            'slug'         => 'anxiety-support',
            'name'         => 'Anxiety Support',
            'description'  => 'A calm place to talk.',
            'channel_type' => 'support_circle',
        ]);
    }

    private function token(): string
    {
        return $this->user->createToken('test')->plainTextToken;
    }

    public function test_channels_are_listed_without_archived_ones(): void
    {
        CommunityChannel::create([
            'created_by'  => $this->user->id,
            'slug'        => 'retired',
            'name'        => 'Retired Channel',
            'is_archived' => true,
        ]);

        $this->withToken($this->token())->getJson('/api/community/channels')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonStructure(['data' => [['id', 'slug', 'name', 'description', 'member_count', 'channel_type']]])
            ->assertJsonPath('data.0.slug', 'anxiety-support');
    }

    public function test_opening_a_channel_joins_the_caller_once(): void
    {
        $this->withToken($this->token())->getJson("/api/community/channels/{$this->channel->id}")
            ->assertOk()
            ->assertJsonPath('member_count', 1);

        $this->withToken($this->token())->getJson("/api/community/channels/{$this->channel->id}")
            ->assertOk()
            ->assertJsonPath('member_count', 1);

        $this->assertDatabaseCount('community_channel_members', 1);
    }

    public function test_post_is_created_and_listed_newest_first(): void
    {
        $this->withToken($this->token())->postJson("/api/community/channels/{$this->channel->id}/posts", [
            'content' => 'First day here.',
        ])->assertCreated()->assertJsonPath('author.id', $this->user->id);

        $second = $this->withToken($this->token())->postJson("/api/community/channels/{$this->channel->id}/posts", [
            'content' => 'Second thought.',
        ])->assertCreated()->json('id');

        $this->withToken($this->token())->getJson("/api/community/channels/{$this->channel->id}/posts")
            ->assertOk()
            ->assertJsonCount(2, 'data')
            ->assertJsonPath('data.0.id', $second)
            ->assertJsonStructure(['data' => [['id', 'content', 'author' => ['id', 'name']]], 'meta' => ['total']]);
    }

    public function test_post_requires_content(): void
    {
        $this->withToken($this->token())->postJson("/api/community/channels/{$this->channel->id}/posts", [])
            ->assertJsonValidationErrors('content');
    }

    public function test_post_can_be_reported(): void
    {
        $postId = $this->withToken($this->token())->postJson("/api/community/channels/{$this->channel->id}/posts", [
            'content' => 'Buy my coaching course now!',
        ])->assertCreated()->json('id');

        $this->withToken($this->token())->postJson("/api/community/posts/{$postId}/report", [
            'reason' => 'spam',
        ])->assertCreated()->assertJsonPath('status', 'pending');

        $this->assertDatabaseHas('community_reports', [
            'reporter_id' => $this->user->id,
            'subject_id'  => $postId,
            'reason'      => 'spam',
        ]);
    }
}
