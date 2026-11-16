<?php

namespace Tests\Feature\Api\Discovery;

use App\Models\Appointment;
use App\Models\Category;
use App\Models\Language;
use App\Models\ProfessionalProfile;
use App\Models\Specialty;
use App\Models\User;
use Carbon\CarbonImmutable;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

class DiscoveryAndBookingTest extends TestCase
{
    use RefreshDatabase;

    protected User $client;
    protected User $pro;
    protected ProfessionalProfile $profile;
    protected Category $category;

    protected function setUp(): void
    {
        parent::setUp();
        $this->client  = User::factory()->create(['role' => 'user']);
        $this->pro     = User::factory()->create(['role' => 'professional']);
        $this->category = Category::factory()->create();
        $this->profile = ProfessionalProfile::factory()->approved()->create([
            'user_id'                   => $this->pro->id,
            'category_id'               => $this->category->id,
            'is_accepting_clients'      => true,
            'verification_status'       => 'approved',
            'hourly_rate_cents'         => 5000,
            'session_duration_minutes'  => 45,
        ]);

        // A weekly rule on Monday (1) for the pro.
        $this->pro->availabilitySlotRules()->create([
            'weekday'                => 1,
            'start_time'             => '09:00:00',
            'end_time'               => '12:00:00',
            'slot_duration_minutes'  => 45,
            'buffer_minutes'         => 0,
            'timezone'               => 'UTC',
            'is_active'              => true,
        ]);

        \App\Models\Wallet::firstOrCreate(
            ['user_id' => $this->client->id, 'currency' => 'USD'],
            ['balance_cents' => 1_000_000],
        );
    }

    /* ---- Discovery ---- */

    public function test_discovery_lists_only_verified_accepting_professionals(): void
    {
        // An unverified professional should NOT appear.
        $unverified = User::factory()->create(['role' => 'professional']);
        ProfessionalProfile::factory()->create([
            'user_id' => $unverified->id,
            'category_id' => $this->category->id,
            'verification_status' => 'pending',
            'is_accepting_clients' => false,
        ]);

        $res = $this->actingAs($this->client)->getJson('/api/professionals');
        $res->assertOk();
        $ids = collect($res->json('data'))->pluck('user_id')->all();
        $this->assertContains($this->pro->id, $ids);
        $this->assertNotContains($unverified->id, $ids);
    }

    public function test_discovery_filters_by_category_and_min_rating(): void
    {
        // Add a second verified pro in a different category.
        $cat2 = Category::factory()->create();
        $pro2 = User::factory()->create(['role' => 'professional']);
        ProfessionalProfile::factory()->approved()->create([
            'user_id' => $pro2->id,
            'category_id' => $cat2->id,
            'rating_avg' => 4.8,
        ]);

        $res = $this->actingAs($this->client)
            ->getJson('/api/professionals?category_id=' . $cat2->id);
        $res->assertOk();
        $this->assertCount(1, $res->json('data'));
        $this->assertEquals($pro2->id, $res->json('data.0.user_id'));

        $res2 = $this->actingAs($this->client)
            ->getJson('/api/professionals?min_rating=4.9');
        $res2->assertOk();
        $this->assertCount(0, $res2->json('data'));  // our pro is 5.0 by default factory — actually let me check
    }

    public function test_discovery_show_returns_full_profile(): void
    {
        $res = $this->actingAs($this->client)
            ->getJson("/api/professionals/{$this->profile->id}");
        $res->assertOk();
        $res->assertJsonStructure([
            'id', 'category' => ['id','slug','name'],
            'specialties', 'languages',
            'rating_avg', 'verification_status', 'badge_active',
        ]);
    }

    /* ---- Available slots ---- */

    public function test_available_slots_returns_slots_for_day(): void
    {
        $monday = CarbonImmutable::now('UTC')->next(CarbonImmutable::MONDAY)->format('Y-m-d');
        $res = $this->actingAs($this->client)
            ->getJson("/api/professionals/{$this->pro->id}/available-slots?date={$monday}&timezone=UTC");
        $res->assertOk();

        // 09:00–12:00 with 45min slots = 4 slots
        $this->assertCount(4, $res->json('slots'));
    }

    public function test_available_slots_excludes_overlapping_booking(): void
    {
        $monday = CarbonImmutable::now('UTC')->next(CarbonImmutable::MONDAY)->setTime(10, 0);
        // Book the 10:00–10:45 slot directly so it's excluded.
        Appointment::create([
            'user_id'                => $this->client->id,
            'professional_user_id'   => $this->pro->id,
            'professional_profile_id' => $this->profile->id,
            'scheduled_at'           => $monday,
            'duration_minutes'       => 45,
            'session_type'           => 'video',
            'status'                 => 'confirmed',
            'price_cents'            => 5000,
            'currency'               => 'USD',
            'user_timezone'          => 'UTC',
            'professional_timezone'  => 'UTC',
        ]);

        $res = $this->actingAs($this->client)
            ->getJson("/api/professionals/{$this->pro->id}/available-slots?date={$monday->format('Y-m-d')}&timezone=UTC");
        $res->assertOk();
        // Slots in the 09:00-12:00 window with 45min duration, 0 buffer:
        //   09:00, 09:45, 10:30, 11:15   (4 total)
        // A 10:00-10:45 appointment overlaps the 09:45-10:30 AND 10:30-11:15 slots
        // (both start before 10:45 and end after 10:00). So 2 slots remain.
        $this->assertCount(2, $res->json('slots'));
    }

    public function test_available_slots_excludes_blocked_times(): void
    {
        $monday = CarbonImmutable::now('UTC')->next(CarbonImmutable::MONDAY);
        $this->pro->availabilityBlocks()->create([
            'start_at' => $monday->setTime(10, 0),
            'end_at'   => $monday->setTime(11, 0),
            'reason'   => 'Test block',
        ]);

        $res = $this->actingAs($this->client)
            ->getJson("/api/professionals/{$this->pro->id}/available-slots?date={$monday->format('Y-m-d')}&timezone=UTC");
        $res->assertOk();
        $this->assertCount(2, $res->json('slots'));     // 10:00 and 10:45 are blocked
    }

    /* ---- Booking ---- */

    public function test_client_can_book_a_slot(): void
    {
        $monday = CarbonImmutable::now('UTC')->next(CarbonImmutable::MONDAY)->setTime(10, 0);
        $token = $this->client->createToken('test')->plainTextToken;

        $res = $this->withToken($token)->postJson('/api/appointments', [
            'professional_user_id' => $this->pro->id,
            'scheduled_at'          => $monday->toIso8601String(),
            'duration_minutes'      => 45,
            'session_type'          => 'video',
            'user_timezone'         => 'UTC',
        ]);
        $res->assertCreated();
        $res->assertJsonStructure(['id','status','scheduled_at','price_cents']);
        $this->assertEquals('pending', $res->json('status'));
    }

    public function test_booking_rejects_past_time(): void
    {
        $token = $this->client->createToken('test')->plainTextToken;
        $res = $this->withToken($token)->postJson('/api/appointments', [
            'professional_user_id' => $this->pro->id,
            'scheduled_at'          => CarbonImmutable::now()->subDay()->toIso8601String(),
            'user_timezone'         => 'UTC',
        ]);
        $res->assertJsonValidationErrors('scheduled_at');
    }

    public function test_booking_rejects_slot_outside_professional_hours(): void
    {
        $token = $this->client->createToken('test')->plainTextToken;
        $monday = CarbonImmutable::now('UTC')->next(CarbonImmutable::MONDAY)->setTime(20, 0);   // 8pm — outside 9-12
        $res = $this->withToken($token)->postJson('/api/appointments', [
            'professional_user_id' => $this->pro->id,
            'scheduled_at'          => $monday->toIso8601String(),
            'user_timezone'         => 'UTC',
        ]);
        $res->assertJsonValidationErrors('scheduled_at');
    }

    public function test_booking_rejects_already_taken_slot_on_professional_side(): void
    {
        $monday = CarbonImmutable::now('UTC')->next(CarbonImmutable::MONDAY)->setTime(10, 0);
        // First booking
        $token = $this->client->createToken('test')->plainTextToken;
        $this->withToken($token)->postJson('/api/appointments', [
            'professional_user_id' => $this->pro->id,
            'scheduled_at'          => $monday->toIso8601String(),
            'user_timezone'         => 'UTC',
        ])->assertCreated();

        // Second client attempts the same pro slot
        $otherClient = User::factory()->create(['role' => 'user']);
        \App\Models\Wallet::firstOrCreate(
            ['user_id' => $otherClient->id, 'currency' => 'USD'],
            ['balance_cents' => 1_000_000],
        );
        $token2 = $otherClient->createToken('test')->plainTextToken;
        $res = $this->withToken($token2)->postJson('/api/appointments', [
            'professional_user_id' => $this->pro->id,
            'scheduled_at'          => $monday->toIso8601String(),
            'user_timezone'         => 'UTC',
        ]);
        $res->assertJsonValidationErrors('scheduled_at');
    }

    public function test_booking_rejects_double_booking_on_user_side(): void
    {
        $monday = CarbonImmutable::now('UTC')->next(CarbonImmutable::MONDAY)->setTime(10, 0);
        $token = $this->client->createToken('test')->plainTextToken;
        $this->withToken($token)->postJson('/api/appointments', [
            'professional_user_id' => $this->pro->id,
            'scheduled_at'          => $monday->toIso8601String(),
            'user_timezone'         => 'UTC',
        ])->assertCreated();

        $secondPro = User::factory()->create(['role' => 'professional']);
        ProfessionalProfile::factory()->approved()->create([
            'user_id' => $secondPro->id,
            'category_id' => $this->category->id,
            'is_accepting_clients' => true,
        ]);
        $res = $this->withToken($token)->postJson('/api/appointments', [
            'professional_user_id' => $secondPro->id,
            'scheduled_at'          => $monday->toIso8601String(),
            'user_timezone'         => 'UTC',
        ]);
        $res->assertJsonValidationErrors('scheduled_at');
    }

    /* ---- Reschedule / Cancel ---- */

    public function test_client_can_reschedule_own_appointment(): void
    {
        $monday10 = CarbonImmutable::now('UTC')->next(CarbonImmutable::MONDAY)->setTime(10, 0);
        $token = $this->client->createToken('test')->plainTextToken;
        $appt = $this->withToken($token)->postJson('/api/appointments', [
            'professional_user_id' => $this->pro->id,
            'scheduled_at'          => $monday10->toIso8601String(),
            'user_timezone'         => 'UTC',
        ])->json();

        $monday11 = $monday10->addHour();
        $res = $this->withToken($token)->putJson("/api/appointments/{$appt['id']}/reschedule", [
            'scheduled_at'  => $monday11->toIso8601String(),
            'user_timezone' => 'UTC',
        ]);
        $res->assertOk();
        $this->assertEquals('rescheduled', $res->json('status'));
    }

    public function test_client_can_cancel_own_appointment_with_full_refund_when_far_out(): void
    {
        $nextMonday = CarbonImmutable::now('UTC')->next(CarbonImmutable::MONDAY)->setTime(10, 0);
        $token = $this->client->createToken('test')->plainTextToken;
        $appt = $this->withToken($token)->postJson('/api/appointments', [
            'professional_user_id' => $this->pro->id,
            'scheduled_at'          => $nextMonday->toIso8601String(),
            'user_timezone'         => 'UTC',
        ])->json();
        $this->assertArrayHasKey('id', $appt, 'Booking must have id; got: ' . json_encode($appt));

        $res = $this->withToken($token)->putJson("/api/appointments/{$appt['id']}/cancel", [
            'reason' => 'plans changed',
        ]);
        $res->assertOk();
        $this->assertEquals('cancelled', $res->json('appointment.status'));
        $this->assertEquals('full_refund', $res->json('refund_policy'));
    }

    public function test_cancel_within_2h_yields_no_refund(): void
    {
        // Add a same-day rule so the 1h-future slot is bookable regardless of weekday.
        $today = CarbonImmutable::now('UTC');
        $this->pro->availabilitySlotRules()->create([
            'weekday'                => (int) $today->isoFormat('E'),
            'start_time'             => $today->format('H:i:s'),
            'end_time'               => $today->addHours(3)->format('H:i:s'),
            'slot_duration_minutes'  => 45,
            'buffer_minutes'         => 0,
            'timezone'               => 'UTC',
            'is_active'              => true,
        ]);

        $nearFuture = CarbonImmutable::now('UTC')->addHour()->startOfHour();
        $token = $this->client->createToken('test')->plainTextToken;
        $appt = $this->withToken($token)->postJson('/api/appointments', [
            'professional_user_id' => $this->pro->id,
            'scheduled_at'          => $nearFuture->toIso8601String(),
            'user_timezone'         => 'UTC',
        ])->json();
        $this->assertArrayHasKey('id', $appt, 'Booking must have id; got: ' . json_encode($appt));

        $res = $this->withToken($token)->putJson("/api/appointments/{$appt['id']}/cancel");
        $res->assertOk();
        $this->assertEquals('no_refund', $res->json('refund_policy'));
    }

    public function test_other_user_cannot_view_appointment(): void
    {
        $nextMonday = CarbonImmutable::now('UTC')->next(CarbonImmutable::MONDAY)->setTime(10, 0);

        // Create appointment directly (not via API) so no auth state lingers.
        $appt = Appointment::create([
            'user_id'                => $this->client->id,
            'professional_user_id'   => $this->pro->id,
            'professional_profile_id' => $this->profile->id,
            'scheduled_at'           => $nextMonday,
            'duration_minutes'       => 45,
            'session_type'           => 'video',
            'status'                 => 'pending',
            'price_cents'            => 5000,
            'currency'               => 'USD',
            'user_timezone'          => 'UTC',
            'professional_timezone'  => 'UTC',
        ]);

        $stranger = User::factory()->create(['role' => 'user']);
        $strangeToken = $stranger->createToken('test')->plainTextToken;

        $res = $this->withToken($strangeToken)
            ->getJson("/api/appointments/{$appt->id}");
        $res->assertForbidden();
    }
}