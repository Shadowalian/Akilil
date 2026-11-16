<?php

namespace Tests\Feature\Api\Session;

use App\Models\Appointment;
use App\Models\CallSession;
use App\Models\Category;
use App\Models\ProfessionalProfile;
use App\Models\User;
use Carbon\CarbonImmutable;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class SessionLifecycleTest extends TestCase
{
    use RefreshDatabase;

    protected User $client;
    protected User $pro;
    protected Appointment $appointment;

    protected function setUp(): void
    {
        parent::setUp();
        $this->client = User::factory()->create(['role' => 'user']);
        $this->pro    = User::factory()->create(['role' => 'professional']);
        $cat = Category::factory()->create();
        $profile = ProfessionalProfile::factory()->approved()->create([
            'user_id' => $this->pro->id, 'category_id' => $cat->id,
        ]);
        $this->appointment = Appointment::create([
            'user_id'                => $this->client->id,
            'professional_user_id'   => $this->pro->id,
            'professional_profile_id' => $profile->id,
            'scheduled_at'           => CarbonImmutable::now('UTC')->subMinutes(5),   // within join window
            'duration_minutes'       => 45,
            'session_type'           => 'video',
            'status'                 => 'confirmed',
            'price_cents'            => 5000,
            'currency'               => 'USD',
            'user_timezone'          => 'UTC',
            'professional_timezone'  => 'UTC',
        ]);
    }

    public function test_parties_can_start_a_session(): void
    {
        $token = $this->client->createToken('test')->plainTextToken;
        $res = $this->withToken($token)->postJson("/api/appointments/{$this->appointment->id}/session/start");
        $res->assertOk()->assertJsonStructure([
            'session' => ['id', 'room_url', 'room_name', 'token', 'started_at'],
            'appointment' => ['id', 'status'],
        ]);
        $this->assertEquals('in_progress', $res->json('appointment.status'));
        $this->assertDatabaseHas('call_sessions', ['appointment_id' => $this->appointment->id, 'status' => 'active']);
    }

    public function test_stranger_cannot_start_a_session(): void
    {
        $stranger = User::factory()->create(['role' => 'user']);
        $token = $stranger->createToken('test')->plainTextToken;
        $this->withToken($token)
            ->postJson("/api/appointments/{$this->appointment->id}/session/start")
            ->assertForbidden();
    }

    public function test_session_end_marks_completed(): void
    {
        CallSession::create([
            'appointment_id' => $this->appointment->id,
            'started_at'     => now()->subMinutes(30),
            'room_name'      => 'friend-' . $this->appointment->id . '-abc',
            'status'         => 'active',
        ]);
        $this->appointment->update(['status' => 'in_progress', 'started_at' => now()->subMinutes(30)]);

        $token = $this->pro->createToken('test')->plainTextToken;
        $res = $this->withToken($token)->postJson("/api/appointments/{$this->appointment->id}/session/end");
        $res->assertOk()->assertJsonStructure(['session' => ['id', 'duration_seconds', 'recording_status']]);
        $this->assertEquals('completed', $this->appointment->fresh()->status);
    }

    public function test_jitsi_webhook_marks_recording_ready(): void
    {
        $cs = CallSession::create([
            'appointment_id' => $this->appointment->id,
            'started_at'     => now()->subMinutes(10),
            'room_name'      => 'friend-' . $this->appointment->id . '-abc',
            'status'         => 'active',
        ]);
        $res = $this->postJson('/api/webhooks/jitsi', [
            'event'      => 'recording_ready',
            'room'       => $cs->room_name,
            'url'        => 'https://recordings.example.com/abc.mp4',
            'size_bytes' => 12345678,
            'duration'   => 1800,
        ]);
        $res->assertOk();
        $this->assertDatabaseHas('call_sessions', [
            'id'                => $cs->id,
            'recording_status'  => 'ready',
            'recording_url'     => 'https://recordings.example.com/abc.mp4',
            'recording_size_bytes' => 12345678,
        ]);
    }

    public function test_session_start_rejected_when_status_not_confirmed(): void
    {
        $this->appointment->update(['status' => 'cancelled']);
        $token = $this->client->createToken('test')->plainTextToken;
        $this->withToken($token)
            ->postJson("/api/appointments/{$this->appointment->id}/session/start")
            ->assertJsonValidationErrors('status');
    }

    public function test_client_cannot_end_session_for_everyone(): void
    {
        CallSession::create([
            'appointment_id' => $this->appointment->id,
            'started_at'     => now()->subMinutes(10),
            'room_name'      => 'akilil-'.$this->appointment->id.'-abc',
            'status'         => 'active',
        ]);
        $this->appointment->update(['status' => 'in_progress', 'started_at' => now()->subMinutes(10)]);

        $token = $this->client->createToken('test')->plainTextToken;
        $this->withToken($token)
            ->postJson("/api/appointments/{$this->appointment->id}/session/end")
            ->assertForbidden();
    }

    public function test_rejoin_reuses_same_room_name(): void
    {
        $token = $this->client->createToken('test')->plainTextToken;
        $first = $this->withToken($token)
            ->postJson("/api/appointments/{$this->appointment->id}/session/start")
            ->assertOk()
            ->json('session.room_name');

        $second = $this->withToken($token)
            ->postJson("/api/appointments/{$this->appointment->id}/session/start")
            ->assertOk()
            ->json('session.room_name');

        $this->assertSame($first, $second);
        $this->assertStringContainsString('config.prejoinPageEnabled=', 
            $this->withToken($token)
                ->postJson("/api/appointments/{$this->appointment->id}/session/start")
                ->json('session.room_url')
        );
    }
}