<?php

namespace App\Http\Controllers\Api\Auth;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\Auth\ForgotPasswordRequest;
use App\Http\Requests\Api\Auth\ResetPasswordRequest;
use App\Models\User;
use App\Notifications\PasswordResetCodeNotification;
use Illuminate\Auth\Events\PasswordReset;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;

/**
 * Password reset for the mobile apps: a 6-digit code by email, typed into
 * the app. (Laravel's default flow emails a link to a web page we don't
 * have, with a 64-character token nobody can type.)
 */
class PasswordController extends Controller
{
    private const TTL_MINUTES = 15;

    private const MAX_ATTEMPTS = 5;

    /** POST /api/auth/forgot-password  { email } */
    public function sendLink(ForgotPasswordRequest $request): JsonResponse
    {
        $email = strtolower($request->string('email')->toString());
        $user = User::where('email', $email)->first();

        if ($user) {
            $code = (string) random_int(100000, 999999);
            Cache::put($this->key($email), ['hash' => Hash::make($code), 'attempts' => 0], now()->addMinutes(self::TTL_MINUTES));
            $user->notify(new PasswordResetCodeNotification($code));
        }

        // Same answer either way, so nobody can probe which emails have accounts.
        return response()->json(['message' => 'If that email has an account, we sent a 6-digit code to it.']);
    }

    /** POST /api/auth/reset-password  { email, token (the code), password, password_confirmation } */
    public function reset(ResetPasswordRequest $request): JsonResponse
    {
        $email = strtolower($request->string('email')->toString());
        $entry = Cache::get($this->key($email));
        $user = User::where('email', $email)->first();

        $fail = fn () => throw ValidationException::withMessages(['token' => ['That code is wrong or has expired. Ask for a new one.']]);

        if (! $entry || ! $user) {
            $fail();
        }
        if ($entry['attempts'] >= self::MAX_ATTEMPTS) {
            Cache::forget($this->key($email));
            $fail();
        }
        if (! Hash::check(preg_replace('/\D/', '', $request->string('token')->toString()), $entry['hash'])) {
            Cache::put($this->key($email), [...$entry, 'attempts' => $entry['attempts'] + 1], now()->addMinutes(self::TTL_MINUTES));
            $fail();
        }

        Cache::forget($this->key($email));
        $user->forceFill([
            'password'       => Hash::make($request->string('password')->toString()),
            'remember_token' => Str::random(60),
        ])->save();
        // Sign out every device: whoever had the old password is out.
        $user->tokens()->delete();
        event(new PasswordReset($user));

        return response()->json(['message' => 'Password changed. Sign in with your new password.']);
    }

    private function key(string $email): string
    {
        return 'pw-reset:'.sha1($email);
    }
}
