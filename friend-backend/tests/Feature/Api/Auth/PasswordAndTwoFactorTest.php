<?php

namespace Tests\Feature\Api\Auth;

use App\Models\User;
use App\Notifications\PasswordResetCodeNotification;
use App\Services\TwoFactorService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Notification;
use Tests\TestCase;

class PasswordAndTwoFactorTest extends TestCase
{
    use RefreshDatabase;

    public function test_password_reset_by_emailed_code(): void
    {
        Notification::fake();
        $user = User::factory()->create(['email' => 'reset@example.com']);
        $user->createToken('old-phone');

        $this->postJson('/api/auth/forgot-password', ['email' => 'Reset@Example.com'])->assertOk();
        $code = null;
        Notification::assertSentTo($user, PasswordResetCodeNotification::class, function ($n) use (&$code) {
            $code = $n->code;

            return true;
        });

        $payload = ['email' => 'reset@example.com', 'password' => 'New-pass-9', 'password_confirmation' => 'New-pass-9'];
        $this->postJson('/api/auth/reset-password', [...$payload, 'token' => '000000'])->assertStatus(422);
        $this->postJson('/api/auth/reset-password', [...$payload, 'token' => $code])->assertOk();

        $this->assertSame(0, $user->tokens()->count());
        $this->postJson('/api/auth/login', ['email' => 'reset@example.com', 'password' => 'New-pass-9'])->assertOk();
        // A code works once.
        $this->postJson('/api/auth/reset-password', [...$payload, 'token' => $code])->assertStatus(422);
    }

    public function test_unknown_email_gets_the_same_answer(): void
    {
        Notification::fake();
        $this->postJson('/api/auth/forgot-password', ['email' => 'nobody@example.com'])->assertOk();
        Notification::assertNothingSent();
    }

    public function test_reset_codes_lock_after_five_wrong_tries(): void
    {
        Notification::fake();
        $user = User::factory()->create(['email' => 'lock@example.com']);
        $this->postJson('/api/auth/forgot-password', ['email' => 'lock@example.com']);
        $code = null;
        Notification::assertSentTo($user, PasswordResetCodeNotification::class, function ($n) use (&$code) {
            $code = $n->code;

            return true;
        });
        $payload = ['email' => 'lock@example.com', 'password' => 'New-pass-9', 'password_confirmation' => 'New-pass-9'];
        foreach (range(1, 5) as $_) {
            $this->postJson('/api/auth/reset-password', [...$payload, 'token' => '111111']);
        }
        $this->postJson('/api/auth/reset-password', [...$payload, 'token' => $code])->assertStatus(422);
    }

    public function test_login_with_two_factor_issues_a_token_after_the_code(): void
    {
        $svc = app(TwoFactorService::class);
        $secret = $svc->generateSecret();
        $user = User::factory()->create(['email' => 'tfa@example.com', 'password' => 'Pass-word-9', 'totp_secret' => $secret, 'totp_enabled' => true, 'totp_confirmed_at' => now()]);

        $res = $this->postJson('/api/auth/login', ['email' => 'tfa@example.com', 'password' => 'Pass-word-9'])
            ->assertOk()->assertJsonPath('requires_2fa', true)->assertJsonPath('token', null);

        $this->postJson('/api/auth/2fa/challenge', ['challenge_token' => $res->json('challenge_token'), 'code' => $svc->currentCode($secret)])
            ->assertOk()->assertJsonStructure(['token', 'user' => ['id']]);
    }
}
