<?php

namespace App\Http\Controllers\Api\Auth;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\Auth\RegisterRequest;
use App\Http\Resources\TokenResource;
use App\Models\User;
use App\Models\Wallet;
use Illuminate\Auth\Events\Registered;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;

class RegisterController extends Controller
{
    /**
     * POST /api/auth/register
     * Creates a regular end-user (users.role = 'user').
     */
    public function __invoke(RegisterRequest $request): JsonResponse
    {
        // Adults only sign themselves up. A minor is added by a parent or
        // guardian from the guardian's own account (POST /api/dependents).
        $age = (int) Carbon::parse($request->input('date_of_birth'))->diffInYears(now());
        if ($age < (int) config('akilil.adult_age')) {
            return response()->json([
                'message' => 'You need to be 18 or older to create an account. '
                    .'Ask a parent or guardian to sign up and add you — they can book and pay for your sessions.',
                'code'    => 'guardian_required',
                'errors'  => ['date_of_birth' => ['A parent or guardian must create the account for anyone under 18.']],
            ], 422);
        }

        return DB::transaction(function () use ($request) {
            $user = User::create([
                'name'     => $request->string('name')->toString(),
                'email'    => $request->string('email')->toString(),
                'password' => $request->string('password')->toString(),
                'role'     => 'user',
                'locale'   => $request->input('locale') ?? config('app.locale', 'en'),
                'timezone' => $request->input('timezone') ?? 'UTC',
                'date_of_birth'    => $request->input('date_of_birth'),
                'seeking_care_for' => $request->input('seeking_care_for') ?: 'self',
                'gender'           => $request->input('gender'),
                'phone'            => $request->input('phone'),
                'terms_accepted_at' => now(),
                'email_verified_at' => null,        // explicit: requires verification
            ]);

            // Every user gets a zero-balance wallet.
            Wallet::create([
                'user_id'  => $user->id,
                'currency' => config('akilil.currency'),
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