<?php

namespace App\Http\Controllers\Api\Auth;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\Auth\RegisterRequest;
use App\Http\Resources\TokenResource;
use App\Models\User;
use App\Models\Wallet;
use Illuminate\Auth\Events\Registered;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;

class RegisterController extends Controller
{
    /**
     * POST /api/auth/register
     * Creates a regular end-user (users.role = 'user').
     */
    public function __invoke(RegisterRequest $request): JsonResponse
    {
        return DB::transaction(function () use ($request) {
            $user = User::create([
                'name'     => $request->string('name')->toString(),
                'email'    => $request->string('email')->toString(),
                'password' => $request->string('password')->toString(),
                'role'     => 'user',
                'locale'   => $request->input('locale') ?? config('app.locale', 'en'),
                'timezone' => $request->input('timezone') ?? 'UTC',
                'email_verified_at' => null,        // explicit: requires verification
            ]);

            // Every user gets a zero-balance wallet.
            Wallet::create([
                'user_id'  => $user->id,
                'currency' => 'USD',
            ]);

            event(new Registered($user));

            $deviceName = $request->input('device_name') ?: $request->userAgent() ?: 'unknown';
            $token = $user->createToken($deviceName);

            return response()->json(
                (new TokenResource(
                    token: $token->plainTextToken,
                    user:  $user,
                    expiresAt: $token->accessToken->expires_at ?? now()->addDays(7),
                ))->toArray($request),
                201
            );
        });
    }
}