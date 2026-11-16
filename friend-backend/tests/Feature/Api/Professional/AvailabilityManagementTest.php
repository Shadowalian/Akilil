<?php

namespace Tests\Feature\Api\Professional;

use App\Models\AvailabilityBlock;
use App\Models\AvailabilitySlotRule;
use App\Models\Category;
use App\Models\ProfessionalProfile;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AvailabilityManagementTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->pro = User::factory()->create(['role' => 'professional']);
        $cat = Category::factory()->create();
        ProfessionalProfile::factory()->approved()->create([
            'user_id' => $this->pro->id,
            'category_id' => $cat->id,
        ]);
    }

    public function test_professional_can_create_a_recurring_rule(): void
    {
        $token = $this->pro->createToken('test')->plainTextToken;
        $res = $this->withToken($token)->postJson('/api/professional/availability/rules', [
            'weekday'                => 2,
            'start_time'             => '10:00',
            'end_time'               => '14:00',
            'slot_duration_minutes'  => 45,
            'buffer_minutes'         => 15,
            'timezone'               => 'Africa/Addis_Ababa',
        ]);
        $res->assertCreated();
        $this->assertDatabaseHas('availability_slot_rules', [
            'user_id'  => $this->pro->id,
            'weekday'  => 2,
            'timezone' => 'Africa/Addis_Ababa',
        ]);
    }

    public function test_professional_can_create_a_block(): void
    {
        $token = $this->pro->createToken('test')->plainTextToken;
        $res = $this->withToken($token)->postJson('/api/professional/availability/blocks', [
            'start_at' => '2026-08-01 09:00:00',
            'end_at'   => '2026-08-01 12:00:00',
            'reason'   => 'Travel',
        ]);
        $res->assertCreated();
        $this->assertDatabaseHas('availability_blocks', [
            'user_id' => $this->pro->id,
            'reason'  => 'Travel',
        ]);
    }

    public function test_end_user_cannot_manage_professional_availability(): void
    {
        $user = User::factory()->create(['role' => 'user']);
        $token = $user->createToken('test')->plainTextToken;
        $this->withToken($token)->postJson('/api/professional/availability/rules', [
            'weekday' => 1, 'start_time' => '09:00', 'end_time' => '10:00',
            'slot_duration_minutes' => 45, 'timezone' => 'UTC',
        ])->assertForbidden();
    }

    public function test_professional_can_list_their_own_rules_and_blocks(): void
    {
        $this->pro->availabilitySlotRules()->create([
            'weekday' => 3, 'start_time' => '09:00', 'end_time' => '12:00',
            'slot_duration_minutes' => 45, 'buffer_minutes' => 0, 'timezone' => 'UTC', 'is_active' => true,
        ]);
        $token = $this->pro->createToken('test')->plainTextToken;
        $res = $this->withToken($token)->getJson('/api/professional/availability');
        $res->assertOk()
            ->assertJsonStructure(['rules' => [], 'blocks' => []])
            ->assertJsonCount(1, 'rules');
    }
}