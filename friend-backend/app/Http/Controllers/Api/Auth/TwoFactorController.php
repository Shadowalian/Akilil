<?php

namespace App\Http\Controllers\Api\Auth;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\Auth\TwoFactorChallengeRequest;
use App\Http\Requests\Api\Auth\TwoFactorConfirmRequest;
use App\Http\Requests\Api\Auth\TwoFactorDisableRequest;
use App\Http\Resources\TokenResource;
use App\Http\Resources\UserResource;
use App\Services\TwoFactorService;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

class TwoFactorController extends Controller
{
    public function __construct(private TwoFactorService $twoFactor) {}

    /**
     * POST /api/auth/2fa/setup (auth required)
     * Generates a fresh secret and returns the otpauth:// URL for QR.
     * Does NOT enable 2FA yet — user must call /confirm with a valid code.
     *
     * If 2FA is already enabled, just return the existing secret (so
     * the user can re-display QR after re-installing their authenticator).
     */
    public function setup(\Illuminate\Http\Request $request): JsonResponse
    {
        $user = $request->user();
        if (! $user->totp_secret) {
            $user->totp_secret = $this->twoFactor->generateSecret();
            $user->save();
        }

        return response()->json([
            'secret'       => $user->totp_secret,
            'otpauth_url'  => $this->twoFactor->otpAuthUrl($user->email, $user->totp_secret),
            'enabled'      => (bool) $user->totp_enabled,
        ]);
    }

    /**
     * POST /api/auth/2fa/confirm (auth required)
     * Validates a TOTP code AND current password; on success marks
     * 2FA enabled, returns the recovery codes (one-time, store now).
     */
    public function confirm(TwoFactorConfirmRequest $request): JsonResponse
    {
        $user = $request->user();
        if (! Hash::check($request->string('password')->toString(), $user->password)) {
            throw ValidationException::withMessages(['password' => ['Password is incorrect.']]);
        }
        if (! $user->totp_secret) {
            throw ValidationException::withMessages(['code' => ['Call /api/auth/2fa/setup first.']]);
        }
        if (! $this->twoFactor->verifyCode($user->totp_secret, $request->string('code')->toString())) {
            throw ValidationException::withMessages(['code' => ['Invalid or expired code.']]);
        }

        $codes = $this->twoFactor->generateRecoveryCodes();
        // Hash for storage; Laravel's encrypted:array cast handles encryption.
        $user->forceFill([
            'totp_enabled'      => true,
            'totp_confirmed_at' => now(),
            'totp_recovery_codes' => array_map(fn ($c) => Hash::make($c), $codes),
        ])->save();

        return response()->json([
            'message'        => 'Two-factor authentication enabled.',
            'recovery_codes' => $codes,         // plaintext — show once.
        ]);
    }

    /**
     * POST /api/auth/2fa/disable (auth required)
     * Validates both current password AND a fresh TOTP code before
     * disabling 2FA. Always require either TOTP code or recovery code
     * to prevent disable-via-stolen-password-only.
     */
    public function disable(TwoFactorDisableRequest $request): JsonResponse
    {
        $user = $request->user();
        if (! Hash::check($request->string('password')->toString(), $user->password)) {
            throw ValidationException::withMessages(['password' => ['Password is incorrect.']]);
        }
        if (! $this->twoFactor->verifyCode($user->totp_secret, $request->string('code')->toString())) {
            throw ValidationException::withMessages(['code' => ['Invalid or expired code.']]);
        }
        $user->forceFill([
            'totp_enabled'      => false,
            'totp_secret'       => null,
            'totp_recovery_codes' => null,
            'totp_confirmed_at' => null,
        ])->save();

        return response()->json(['message' => 'Two-factor authentication disabled.']);
    }

    /**
     * POST /api/auth/2fa/challenge
     * Exchanges a 2FA challenge token (issued by /login) + a TOTP code
     * (or a recovery code) for a real Sanctum token.
     */
    public function challenge(TwoFactorChallengeRequest $request): JsonResponse
    {
        $challenge = Cache::pull("2fa-challenge:{$request->string('challenge_token')->toString()}");
        if (! $challenge) {
            throw ValidationException::withMessages(['challenge_token' => ['Expired or invalid.']]);
        }

        $user = \App\Models\User::find($challenge['user_id']);
        if (! $user) {
            throw ValidationException::withMessages(['challenge_token' => ['Unknown user.']]);
        }

        $code = preg_replace('/\s+/', '', (string) $request->input('code'));
        $valid = $code && $this->twoFactor->verifyCode($user->totp_secret, $code);

        $recoveryCode = $request->input('recovery_code');
        $usedRecoveryIndex = null;
        if (! $valid && $recoveryCode && is_array($user->totp_recovery_codes)) {
            foreach ($user->totp_recovery_codes as $i => $hash) {
                if (Hash::check(strtoupper((string) $recoveryCode), $hash)) {
                    $valid = true;
                    $usedRecoveryIndex = $i;
                    break;
                }
            }
        }

        if (! $valid) {
            throw ValidationException::withMessages(['code' => ['Invalid code or recovery code.']]);
        }

        if ($usedRecoveryIndex !== null) {
            // Burn the used recovery code.
            $codes = $user->totp_recovery_codes;
            unset($codes[$usedRecoveryIndex]);
            $user->forceFill(['totp_recovery_codes' => array_values($codes)])->save();
        }

        $token = $user->createToken('post-2fa-' . substr(md5((string) $request->input('challenge_token')), 0, 8));

        return response()->json(
            (new TokenResource(
                token: $token->plainTextToken,
                user:  $user,
                expiresAt: $token->accessToken->expires_at ?? now()->addDays(7),
            ))->toArray($request)
        );
    }
}