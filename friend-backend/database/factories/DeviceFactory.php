<?php

namespace Database\Factories;

use App\Models\Device;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Device>
 */
class DeviceFactory extends Factory
{
    protected $model = Device::class;

    public function definition(): array
    {
        return [
            'user_id'      => User::factory(),
            'platform'     => fake()->randomElement(['ios', 'android']),
            'push_token'   => fake()->sha256() . bin2hex(random_bytes(8)),
            'app_version'  => '0.1.0',
            'os_version'   => fake()->randomElement(['14.0', '15.0', 'Android 14', 'Android 15']),
            'device_model' => fake()->randomElement(['Pixel 8', 'iPhone 15', 'Galaxy S24', 'iPhone 14']),
            'locale'       => 'en',
            'is_active'    => true,
            'last_seen_at' => now(),
        ];
    }
}