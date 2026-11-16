<?php

namespace App\Http\Controllers\Api\Auth;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\Auth\LoginRequest;
use App\Http\Resources\TokenResource;
use App\Models\User;
use App\Services\TwoFactorService;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;

class LoginController extends Controller
{
    public function __construct(private TwoFactorService $twoFactor) {}

    /**
     * POST /api/auth/login
     *
     * Returns Sanctum token directly, OR short-lived challenge token
     * if the user has 2FA enabled. Either way the password is verified
     * first; we never reveal which case applies to avoid user enumeration.
     */
    public function __invoke(LoginRequest $request): JsonResponse
    {
        $email    = $request->string('email')->toString();
        $password = $request->string('password')->toString();

        $user = User::where('email', $email)->first();
        if (! $user || ! Hash::check($password, $user->password)) {
            throw ValidationException::withMessages([
                'email' => ['The provided credentials are incorrect.'],
            ]);
        }

        // If user has 2FA enabled, defer token issuance.
        if ((bool) $user->totp_enabled) {
            $challenge = Str::random(40);
            Cache::put("2fa-challenge:{$challenge}", [
                'user_id' => $user->id, 'expires_at' => now()->addMinutes(5),
            ], now()->addMinutes(5));
            return response()->json(
                (new TokenResource(
                    token: '',
                    user: null,
                    requires2fa: true,
                    challengeToken: $challenge,
                ))->toArray($request)
            );
        }

        $deviceName = $request->input('device_name') ?: $request->userAgent() ?: 'unknown';
        $token = $user->createToken($deviceName, $this->abilitiesFor($user));

        return response()->json(
            (new TokenResource(
                token: $token->plainTextToken,
                user:  $user,
                expiresAt: $token->accessToken->expires_at ?? now()->addDays(7),
            ))->toArray($request)
        );
    }

    /** Map Spatie roles to Sanctum token abilities. */
    private function abilitiesFor(User $user): array
    {
        if (method_exists($user, 'hasAnyRole') && $user->hasAnyRole(['admin'])) {
            return ['*'];
        }
        if (method_exists($user, 'hasAnyRole') && $user->hasAnyRole(['support','moderator'])) {
            return ['admin:limited'];
        }
        return ['user'];
    }
}