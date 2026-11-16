<?php

namespace Tests\Feature\Api\Auth;

use App\Models\User;
use App\Models\Wallet;
use App\Services\TwoFactorService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

class AuthFlowTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        // Seed the spatie roles used by 2FA + admin gate tests.
        \Spatie\Permission\Models\Role::firstOrCreate(['name' => 'admin',     'guard_name' => 'web']);
        \Spatie\Permission\Models\Role::firstOrCreate(['name' => 'support',   'guard_name' => 'web']);
        \Spatie\Permission\Models\Role::firstOrCreate(['name' => 'moderator', 'guard_name' => 'web']);
    }

    public function test_user_can_register_and_returns_sanctum_token(): void
    {
        $response = $this->postJson('/api/auth/register', [
            'name'                  => 'Test User',
            'email'                 => 'test@example.com',
            'password'              => 'Pass-word-9',
            'password_confirmation' => 'Pass-word-9',
            'date_of_birth'         => '1994-05-17',
            'accept_terms'          => true,
        ]);

        $response->assertCreated();
        $response->assertJsonStructure(['token', 'user' => ['id', 'email', 'role']]);

        $this->assertDatabaseHas('users', ['email' => 'test@example.com', 'role' => 'user']);
        $this->assertDatabaseHas('wallets', ['user_id' => User::where('email', 'test@example.com')->first()->id]);
    }

    public function test_register_requires_unique_email(): void
    {
        User::factory()->create(['email' => 'taken@example.com']);

        $this->postJson('/api/auth/register', [
            'name'                  => 'X',
            'email'                 => 'taken@example.com',
            'password'              => 'Pass-word-9',
            'password_confirmation' => 'Pass-word-9',
        ])->assertJsonValidationErrors('email');
    }

    public function test_register_password_must_be_confirmed(): void
    {
        $this->postJson('/api/auth/register', [
            'name'     => 'X',
            'email'    => 'x@example.com',
            'password' => 'mismatch',
        ])->assertJsonValidationErrors('password');
    }

    public function test_user_can_login_with_correct_credentials(): void
    {
        User::factory()->create(['email' => 'login@example.com', 'password' => Hash::make('correct-password-9')]);

        $this->postJson('/api/auth/login', [
            'email'    => 'login@example.com',
            'password' => 'correct-password-9',
        ])->assertOk()->assertJsonStructure(['token', 'user']);
    }

    public function test_login_rejects_wrong_password(): void
    {
        User::factory()->create(['email' => 'login@example.com', 'password' => Hash::make('correct-9')]);

        $this->postJson('/api/auth/login', [
            'email'    => 'login@example.com',
            'password' => 'wrong-9',
        ])->assertJsonValidationErrors('email');
    }

    public function test_user_with_2fa_enabled_must_challenge_before_getting_token(): void
    {
        $secret = app(TwoFactorService::class)->generateSecret();
        $user = User::factory()->create([
            'email' => '2fa@example.com',
            'password' => Hash::make('correct-9'),
            'totp_secret'    => $secret,
            'totp_enabled'   => true,
            'totp_confirmed_at' => now(),
        ]);

        $res = $this->postJson('/api/auth/login', [
            'email' => '2fa@example.com',
            'password' => 'correct-9',
        ]);

        $res->assertOk();
        $this->assertTrue($res->json('requires_2fa'));
        $this->assertNotEmpty($res->json('challenge_token'));
        $this->assertEmpty($res->json('token'));
    }

    public function test_2fa_challenge_with_valid_code_returns_token(): void
    {
        $svc = app(TwoFactorService::class);
        $secret = $svc->generateSecret();
        $user = User::factory()->create([
            'email'       => '2faok@example.com',
            'password'    => Hash::make('correct-9'),
            'totp_secret' => $secret,
            'totp_enabled'=> true,
            'totp_confirmed_at' => now(),
        ]);

        // Trigger login to get a challenge token.
        $challengeRes = $this->postJson('/api/auth/login', [
            'email' => '2faok@example.com',
            'password' => 'correct-9',
        ])->json();

        $code = $svc->currentCode($secret);

        $res = $this->postJson('/api/auth/2fa/challenge', [
            'challenge_token' => $challengeRes['challenge_token'],
            'code' => $code,
        ]);
        $res->assertOk()->assertJsonStructure(['token']);
    }

    public function test_2fa_challenge_rejects_wrong_code(): void
    {
        $secret = app(TwoFactorService::class)->generateSecret();
        $user = User::factory()->create([
            'email'       => '2fabad@example.com',
            'password'    => Hash::make('correct-9'),
            'totp_secret' => $secret,
            'totp_enabled'=> true,
            'totp_confirmed_at' => now(),
        ]);
        $challengeRes = $this->postJson('/api/auth/login', [
            'email' => '2fabad@example.com',
            'password' => 'correct-9',
        ])->json();

        $this->postJson('/api/auth/2fa/challenge', [
            'challenge_token' => $challengeRes['challenge_token'],
            'code' => '000000',
        ])->assertJsonValidationErrors('code');
    }

    public function test_authenticated_user_can_logout_and_token_is_revoked(): void
    {
        $user = User::factory()->create();
        $token = $user->createToken('test')->plainTextToken;

        $res = $this->withToken($token)->postJson('/api/auth/logout');
        $res->assertOk()->assertJson(['message' => 'Logged out.']);

        // Sanity: token row is actually gone from the DB.
        $this->assertDatabaseMissing('personal_access_tokens', ['name' => 'test']);
    }

    public function test_logout_everywhere_revokes_all_tokens(): void
    {
        $user = User::factory()->create();
        $user->createToken('phone');
        $user->createToken('web');
        $token = $user->createToken('tablet')->plainTextToken;

        $this->withToken($token)->postJson('/api/auth/logout-everywhere')
            ->assertOk();

        $this->assertDatabaseCount('personal_access_tokens', 0);
    }

    public function test_me_returns_user_resource_for_authenticated_user(): void
    {
        $user = User::factory()->create(['email' => 'me@example.com']);
        $token = $user->createToken('test')->plainTextToken;

        $res = $this->withToken($token)->getJson('/api/me');
        $res->assertOk()->assertJson(['email' => 'me@example.com']);
    }

    public function test_me_can_update_locale_and_timezone(): void
    {
        $user = User::factory()->create(['locale' => 'en', 'timezone' => 'UTC']);
        $token = $user->createToken('test')->plainTextToken;

        $this->withToken($token)->putJson('/api/me', [
            'locale'   => 'am',
            'timezone' => 'Africa/Addis_Ababa',
            'name'     => 'Updated Name',
        ])->assertOk()->assertJson(['locale' => 'am', 'timezone' => 'Africa/Addis_Ababa']);

        $this->assertDatabaseHas('users', ['id' => $user->id, 'locale' => 'am', 'timezone' => 'Africa/Addis_Ababa']);
    }

    public function test_admin_must_setup_2fa_before_admin_gated_endpoint(): void
    {
        $admin = User::factory()->create();
        $admin->assignRole('admin');
        $token = $admin->createToken('test', ['*'])->plainTextToken;

        $res = $this->withToken($token)->getJson('/api/admin/health');
        $res->assertStatus(423)->assertJson(['error' => 'two_factor_required']);
    }

    public function test_admin_with_2fa_enabled_can_hit_admin_gated_endpoint(): void
    {
        $secret = app(TwoFactorService::class)->generateSecret();
        $admin = User::factory()->create([
            'totp_secret' => $secret,
            'totp_enabled'=> true,
            'totp_confirmed_at' => now(),
        ]);
        $admin->assignRole('admin');
        $token = $admin->createToken('test', ['*'])->plainTextToken;

        $res = $this->withToken($token)->getJson('/api/admin/health');
        $res->assertOk()->assertJson(['ok' => true]);
    }
}