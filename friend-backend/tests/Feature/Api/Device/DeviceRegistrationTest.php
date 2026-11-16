<?php

namespace Tests\Feature\Api\Device;

use App\Models\Device;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class DeviceRegistrationTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_can_register_a_push_token(): void
    {
        $user = User::factory()->create(['role' => 'user']);
        $token = $user->createToken('test')->plainTextToken;

        $res = $this->withToken($token)->postJson('/api/device-tokens', [
            'platform'    => 'android',
            'push_token'  => 'fcm-test-token-' . uniqid(),
            'app_version' => '0.1.0',
            'os_version'  => 'Android 15',
            'device_model'=> 'Pixel 8',
        ]);

        $res->assertCreated()->assertJsonStructure(['id', 'platform', 'is_active', 'registered_at']);
        $this->assertDatabaseHas('devices', ['user_id' => $user->id, 'platform' => 'android']);
    }

    public function test_re_registration_with_same_token_is_idempotent(): void
    {
        $user = User::factory()->create(['role' => 'user']);
        $token = $user->createToken('test')->plainTextToken;
        $pushToken = 'fcm-test-token-' . uniqid();

        $this->withToken($token)->postJson('/api/device-tokens', [
            'platform' => 'android', 'push_token' => $pushToken,
        ])->assertCreated();

        $this->withToken($token)->postJson('/api/device-tokens', [
            'platform' => 'android', 'push_token' => $pushToken,
        ])->assertCreated();

        $this->assertEquals(1, Device::where('user_id', $user->id)->count());
    }

    public function test_user_can_deactivate_own_device(): void
    {
        $user = User::factory()->create(['role' => 'user']);
        $device = Device::create([
            'user_id' => $user->id, 'platform' => 'ios',
            'push_token' => 'apns-' . uniqid(),
        ]);
        $token = $user->createToken('test')->plainTextToken;

        $this->withToken($token)
            ->postJson("/api/device-tokens/{$device->id}/deactivate")
            ->assertOk();

        $this->assertDatabaseHas('devices', ['id' => $device->id, 'is_active' => 0]);
    }

    public function test_user_cannot_deactivate_another_users_device(): void
    {
        $alice = User::factory()->create(['role' => 'user']);
        $bob   = User::factory()->create(['role' => 'user']);
        $device = Device::create([
            'user_id' => $alice->id, 'platform' => 'android',
            'push_token' => 'fcm-' . uniqid(),
        ]);
        $token = $bob->createToken('test')->plainTextToken;

        $this->withToken($token)
            ->postJson("/api/device-tokens/{$device->id}/deactivate")
            ->assertNotFound();
    }
}