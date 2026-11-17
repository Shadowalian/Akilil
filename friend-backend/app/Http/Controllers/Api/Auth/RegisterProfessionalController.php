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
     * New professionals start `pending` and hidden from clients until an
     * admin reviews their credentials. `akilil.demo_mode` skips review for
     * demos only.
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

            $demo = (bool) config('akilil.demo_mode');

            $categoryId = match (true) {
                $request->filled('category_id') => $request->integer('category_id'),
                $request->filled('category')    => (int) Category::where('slug', $request->input('category'))->value('id'),
                default => (int) (Category::where('slug', 'psychiatry')->value('id')
                    ?? Category::query()->orderBy('id')->value('id') ?? 1),
            };

            ProfessionalProfile::create([
                'user_id'              => $user->id,
                'category_id'          => $categoryId,
                'experience_years'     => $request->filled('experience_years')
                    ? $request->integer('experience_years')
                    : 1,
                'bio'                  => $request->input('bio'),
                'verification_status'  => $demo ? 'approved' : 'pending',
                'badge_active'         => $demo,
                'currency'             => config('akilil.currency'),
                'is_accepting_clients' => $demo,
            ]);

            Wallet::create(['user_id' => $user->id, 'currency' => config('akilil.currency')]);

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