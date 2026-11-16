<?php

namespace Database\Factories;

use App\Models\Appointment;
use App\Models\ProfessionalProfile;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Appointment>
 */
class AppointmentFactory extends Factory
{
    protected $model = Appointment::class;

    public function definition(): array
    {
        $client = User::where('role', 'user')->inRandomOrder()->first() ?? User::factory();
        $profile = ProfessionalProfile::inRandomOrder()->first() ?? ProfessionalProfile::factory();
        $pro = $profile->user;
        $startsAt = fake()->dateTimeBetween('-30 days', '+30 days');
        $duration = 45;

        return [
            'user_id'                  => $client,
            'professional_user_id'     => $pro,
            'professional_profile_id'  => $profile,
            'scheduled_at'             => $startsAt,
            'user_timezone'            => 'Africa/Nairobi',
            'professional_timezone'    => 'UTC',
            'duration_minutes'         => $duration,
            'session_type'             => fake()->randomElement(['video', 'voice']),
            'status'                   => fake()->randomElement(['pending', 'confirmed', 'confirmed', 'completed', 'cancelled']),
            'price_cents'              => 4500,
            'currency'                 => 'USD',
            'confirmed_at'             => null,
            'started_at'               => null,
            'ended_at'                 => null,
        ];
    }
}