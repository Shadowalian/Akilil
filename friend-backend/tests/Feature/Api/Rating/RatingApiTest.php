<?php

namespace Tests\Feature\Api\Rating;

use App\Models\Appointment;
use App\Models\Category;
use App\Models\ProfessionalProfile;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class RatingApiTest extends TestCase
{
    use RefreshDatabase;

    private User $pro;
    private User $client;
    private ProfessionalProfile $profile;
    private Appointment $appointment;

    protected function setUp(): void
    {
        parent::setUp();

        $this->pro    = User::factory()->create(['role' => 'professional']);
        $this->client = User::factory()->create(['role' => 'user']);

        $this->profile = ProfessionalProfile::factory()->approved()->create([
            'user_id'      => $this->pro->id,
            'category_id'  => Category::factory()->create(['is_active' => true])->id,
            'rating_avg'   => 0,
            'rating_count' => 0,
        ]);

        $this->appointment = Appointment::factory()->create([
            'user_id'                 => $this->client->id,
            'professional_user_id'    => $this->pro->id,
            'professional_profile_id' => $this->profile->id,
            'scheduled_at'            => now()->subDay(),
            'status'                  => 'completed',
        ]);
    }

    private function clientToken(): string
    {
        return $this->client->createToken('test')->plainTextToken;
    }

    public function test_client_can_review_completed_session_and_aggregate_is_recomputed(): void
    {
        $this->withToken($this->clientToken())
            ->postJson("/api/appointments/{$this->appointment->id}/reviews", [
                'rating'  => 4,
                'comment' => 'Really helped me sleep.',
            ])
            ->assertCreated()
            ->assertJsonPath('rating', 4);

        $this->assertDatabaseHas('professional_profiles', [
            'id'           => $this->profile->id,
            'rating_count' => 1,
            'rating_avg'   => 4.0,
        ]);
    }

    public function test_second_review_for_the_same_appointment_is_rejected(): void
    {
        $payload = ['rating' => 5];

        $this->withToken($this->clientToken())
            ->postJson("/api/appointments/{$this->appointment->id}/reviews", $payload)
            ->assertCreated();

        $this->withToken($this->clientToken())
            ->postJson("/api/appointments/{$this->appointment->id}/reviews", $payload)
            ->assertJsonValidationErrors('appointment_id');
    }

    public function test_incomplete_session_cannot_be_reviewed(): void
    {
        $this->appointment->update(['status' => 'confirmed']);

        $this->withToken($this->clientToken())
            ->postJson("/api/appointments/{$this->appointment->id}/reviews", ['rating' => 5])
            ->assertJsonValidationErrors('status');
    }

    public function test_professional_cannot_review_their_own_session(): void
    {
        $token = $this->pro->createToken('test')->plainTextToken;

        $this->withToken($token)
            ->postJson("/api/appointments/{$this->appointment->id}/reviews", ['rating' => 5])
            ->assertForbidden();
    }

    public function test_reviews_are_listed_for_a_professional_profile(): void
    {
        $this->withToken($this->clientToken())
            ->postJson("/api/appointments/{$this->appointment->id}/reviews", [
                'rating'       => 5,
                'comment'      => 'Anonymous but grateful.',
                'is_anonymous' => true,
            ])->assertCreated();

        $this->withToken($this->clientToken())->getJson("/api/professionals/{$this->profile->id}/reviews")
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.rating', 5)
            ->assertJsonPath('data.0.client', null)
            ->assertJsonPath('meta.rating_count', 1);
    }
}
