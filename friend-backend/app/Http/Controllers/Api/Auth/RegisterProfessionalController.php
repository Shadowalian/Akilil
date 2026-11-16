<?php

namespace App\Http\Controllers\Api\Auth;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\Auth\RegisterProfessionalRequest;
use App\Http\Resources\TokenResource;
use App\Models\Category;
use App\Models\ProfessionalProfile;
use App\Models\User;
use App\Models\Wallet;
use Illuminate\Auth\Events\Registered;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;

class RegisterProfessionalController extends Controller
{
    /**
     * POST /api/auth/register-professional
     *
     * Creates a user with role='professional' AND a professional_profiles row.
     * During QA signup (name/email/password only), defaults category + auto-approves
     * so the new pro is discoverable for free test video calls.
     */
    public function __invoke(RegisterProfessionalRequest $request): JsonResponse
    {
        return DB::transaction(function () use ($request) {
            $user = User::create([
                'name'     => $request->string('name')->toString(),
                'email'    => $request->string('email')->toString(),
                'password' => $request->string('password')->toString(),
                'role'     => 'professional',
                'locale'   => $request->input('locale') ?? config('app.locale', 'en'),
                'timezone' => $request->input('timezone') ?? 'UTC',
            ]);

            $categoryId = $request->filled('category_id')
                ? $request->integer('category_id')
                : (int) (Category::query()->orderBy('id')->value('id') ?? 1);

            ProfessionalProfile::create([
                'user_id'              => $user->id,
                'category_id'          => $categoryId,
                'experience_years'     => $request->filled('experience_years')
                    ? $request->integer('experience_years')
                    : 1,
                'bio'                  => $request->input('bio') ?: 'Testing account — free video calls enabled.',
                // QA: approved + accepting so phone-created pros show up for test calls.
                'verification_status'  => 'approved',
                'badge_active'         => true,
                'currency'             => 'USD',
                'is_accepting_clients' => true,
            ]);

            Wallet::create(['user_id' => $user->id, 'currency' => 'USD']);

            event(new Registered($user));

            $token = $user->createToken('professional-onboarding');

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