<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\UpdateMeRequest;
use App\Http\Requests\Api\UpdateProfessionalProfileRequest;
use App\Http\Resources\ProfessionalProfileResource;
use App\Http\Resources\UserResource;
use App\Models\Category;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class MeController extends Controller
{
    /**
     * GET /api/me
     */
    public function show(Request $request): JsonResponse
    {
        $user = $request->user()->load(['professionalProfile.specialties', 'professionalProfile.languages']);
        return (new UserResource($user))->response();
    }

    /**
     * PUT /api/me
     * Update the user's profile (locale, timezone, name, gender, dob).
     */
    public function update(UpdateMeRequest $request): JsonResponse
    {
        $user = $request->user();
        $data = $request->validated();

        // A date of birth is an age-gate input: once given it can only be
        // corrected by support, and a guardian-managed teen can't set it.
        if (array_key_exists('date_of_birth', $data) && ($user->date_of_birth || $user->guardian_user_id)) {
            unset($data['date_of_birth']);
        }

        $user->fill($data);
        $user->save();

        return (new UserResource($user->fresh('professionalProfile')))->response();
    }

    /**
     * GET /api/me/professional-profile
     * Convenience endpoint for the Pro app shell. Returns 404 if user
     * isn't a professional.
     */
    public function professionalProfile(Request $request): JsonResponse
    {
        $user = $request->user()->load([
            'professionalProfile.category',
            'professionalProfile.specialties',
            'professionalProfile.languages',
        ]);
        abort_unless($user->professionalProfile, 404, 'No professional profile.');
        return (new ProfessionalProfileResource($user->professionalProfile))->response();
    }

    /**
     * PUT /api/me/professional-profile
     * Updates the caller's professional profile, creating it on first write
     * (a professional registered through the API may not have one yet).
     */
    public function updateProfessionalProfile(UpdateProfessionalProfileRequest $request): JsonResponse
    {
        $user = $request->user();
        abort_unless($user->role === 'professional', 403, 'Only professionals have a professional profile.');

        $data = $request->validated();
        $profile = $user->professionalProfile;

        if (array_key_exists('category_id', $data)) {
            $data['category_id'] = $this->resolveCategoryId($data['category_id']);
        } elseif (! $profile) {
            $data['category_id'] = Category::where('is_active', true)->orderBy('sort_order')->value('id');
            abort_unless($data['category_id'], 422, 'A category is required to create a professional profile.');
        }

        $profile ??= $user->professionalProfile()->make();
        $profile->fill($data);
        $profile->save();

        return (new ProfessionalProfileResource(
            $profile->fresh()->load(['category', 'specialties', 'languages'])
        ))->response();
    }

    /**
     * Clients send either a categories.id or a categories.slug.
     */
    private function resolveCategoryId(string $value): int
    {
        $category = ctype_digit($value)
            ? Category::find((int) $value)
            : Category::where('slug', $value)->first();

        abort_unless($category, 422, 'Unknown category.');
        return $category->id;
    }
}