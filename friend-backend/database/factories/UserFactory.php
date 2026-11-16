<?php

namespace Database\Factories;

use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

/**
 * @extends Factory<User>
 *
 * The default User factory is the base for ALL user personas (end-user,
 * professional, admin). Persona's role can be overridden via $attributes
 * ['role' => 'professional'] etc.
 */
class UserFactory extends Factory
{
    protected $model = User::class;

    public function definition(): array
    {
        return [
            'name'              => fake()->name(),
            'email'             => fake()->unique()->safeEmail(),
            'email_verified_at' => now(),
            'password'          => Hash::make('password'),
            'role'              => 'user',
            'locale'            => 'en',
            'timezone'          => 'Africa/Nairobi',
            'avatar_path'       => null,
            'gender'            => fake()->randomElement(['female', 'male', 'non_binary', 'prefer_not_to_say']),
            'date_of_birth'     => fake()->dateTimeBetween('-65 years', '-18 years')->format('Y-m-d'),
            'remember_token'    => Str::random(10),
        ];
    }

    public function professional(): self
    {
        return $this->state(fn () => ['role' => 'professional']);
    }

    public function unverified(): self
    {
        return $this->state(fn () => ['email_verified_at' => null]);
    }

    public function withTotp(): self
    {
        return $this->state(fn () => [
            'totp_enabled'      => true,
            'totp_secret'       => Str::random(32),
            'totp_confirmed_at' => now(),
        ]);
    }
}