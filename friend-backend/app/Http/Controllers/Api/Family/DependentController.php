<?php

namespace App\Http\Controllers\Api\Family;

use App\Http\Controllers\Controller;
use App\Models\Dependent;
use App\Models\User;
use App\Models\Wallet;
use App\Support\AgeGate;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rules\Password;
use Illuminate\Validation\ValidationException;

/**
 * A parent or legal guardian manages the minors in their care here.
 * Adding a dependent records the guardian's consent to treatment; from
 * then on the guardian books and pays for that child's sessions.
 */
class DependentController extends Controller
{
    private const RELATIONSHIPS = ['parent', 'legal_guardian', 'grandparent', 'other_relative'];

    /** GET /api/dependents */
    public function index(Request $request): JsonResponse
    {
        $dependents = $request->user()->dependents()->orderBy('name')->get();

        return response()->json(['data' => $dependents->map(fn ($d) => $this->present($d))]);
    }

    /** POST /api/dependents */
    public function store(Request $request): JsonResponse
    {
        $guardian = $request->user();
        AgeGate::requireAdultPayer($guardian);
        abort_unless($guardian->role === 'user', 403, 'Only client accounts can add dependents.');

        $data = $request->validate([
            'name'           => ['required', 'string', 'min:2', 'max:191'],
            'date_of_birth'  => ['required', 'date', 'before:today'],
            'gender'         => ['nullable', 'in:female,male,non_binary,prefer_not_to_say'],
            'relationship'   => ['required', 'in:'.implode(',', self::RELATIONSHIPS)],
            'care_notes'     => ['nullable', 'string', 'max:2000'],
            // The guardian attests they have legal authority to consent.
            'guardian_consent' => ['accepted'],
        ], [
            'guardian_consent.accepted' => 'Please confirm you are the parent or legal guardian and consent to care for this child.',
        ]);

        $this->assertMinor($data['date_of_birth']);

        $dependent = Dependent::create([
            'guardian_user_id'    => $guardian->id,
            'name'                => $data['name'],
            'date_of_birth'       => $data['date_of_birth'],
            'gender'              => $data['gender'] ?? null,
            'relationship'        => $data['relationship'],
            'care_notes'          => $data['care_notes'] ?? null,
            'consent_version'     => config('akilil.guardian_consent_version'),
            'consent_accepted_at' => now(),
            'consent_ip'          => $request->ip(),
        ]);

        return response()->json(['dependent' => $this->present($dependent)], 201);
    }

    /** PUT /api/dependents/{id} */
    public function update(Request $request, int $id): JsonResponse
    {
        $dependent = $this->owned($request, $id);

        $data = $request->validate([
            'name'         => ['sometimes', 'string', 'min:2', 'max:191'],
            'gender'       => ['sometimes', 'nullable', 'in:female,male,non_binary,prefer_not_to_say'],
            'relationship' => ['sometimes', 'in:'.implode(',', self::RELATIONSHIPS)],
            'care_notes'   => ['sometimes', 'nullable', 'string', 'max:2000'],
        ]);
        $dependent->update($data);

        return response()->json(['dependent' => $this->present($dependent->fresh())]);
    }

    /** DELETE /api/dependents/{id} */
    public function destroy(Request $request, int $id): JsonResponse
    {
        $dependent = $this->owned($request, $id);

        $hasUpcoming = $dependent->appointments()
            ->whereIn('status', ['pending', 'confirmed', 'in_progress'])
            ->exists();
        abort_if($hasUpcoming, 422, 'Cancel this child\'s upcoming sessions before removing them.');

        DB::transaction(function () use ($dependent) {
            // Removing the child also closes their teen login.
            if ($dependent->linked_user_id) {
                $teen = User::find($dependent->linked_user_id);
                $teen?->tokens()->delete();
                $teen?->delete();
            }
            $dependent->delete();
        });

        return response()->json(['message' => 'Removed.']);
    }

    /**
     * POST /api/dependents/{id}/teen-login
     * Gives a teenager their own sign-in so they can join sessions and
     * message their professional privately. The guardian still books and pays.
     */
    public function createTeenLogin(Request $request, int $id): JsonResponse
    {
        $dependent = $this->owned($request, $id);
        abort_if($dependent->linked_user_id, 422, 'This teen already has a login.');

        $minAge = (int) config('akilil.teen_login_min_age');
        abort_if($dependent->age() < $minAge, 422, "A separate login is available from age {$minAge}. Younger children join from your device.");

        $data = $request->validate([
            'email'    => ['required', 'email:rfc', 'max:191', 'unique:users,email'],
            'password' => ['required', 'confirmed', Password::min(8)->mixedCase()->numbers()],
        ]);

        $teen = DB::transaction(function () use ($dependent, $data, $request) {
            $teen = User::create([
                'name'              => $dependent->name,
                'email'             => $data['email'],
                'password'          => $data['password'],
                'role'              => 'user',
                'guardian_user_id'  => $request->user()->id,
                'date_of_birth'     => $dependent->date_of_birth,
                'gender'            => in_array($dependent->gender, ['female', 'male', 'non_binary', 'prefer_not_to_say'], true) ? $dependent->gender : null,
                'locale'            => $request->user()->locale,
                'timezone'          => $request->user()->timezone,
                'terms_accepted_at' => now(),
            ]);
            Wallet::create(['user_id' => $teen->id, 'currency' => config('akilil.currency')]);
            $dependent->update(['linked_user_id' => $teen->id]);

            return $teen;
        });

        return response()->json([
            'message'   => 'Teen login created.',
            'dependent' => $this->present($dependent->fresh()),
            'teen_user_id' => $teen->id,
        ], 201);
    }

    /** DELETE /api/dependents/{id}/teen-login */
    public function revokeTeenLogin(Request $request, int $id): JsonResponse
    {
        $dependent = $this->owned($request, $id);
        abort_unless($dependent->linked_user_id, 422, 'This child has no separate login.');

        DB::transaction(function () use ($dependent) {
            $teen = User::find($dependent->linked_user_id);
            $teen?->tokens()->delete();
            $teen?->delete();
            $dependent->update(['linked_user_id' => null]);
        });

        return response()->json(['message' => 'Teen login removed.', 'dependent' => $this->present($dependent->fresh())]);
    }

    private function owned(Request $request, int $id): Dependent
    {
        return Dependent::where('guardian_user_id', $request->user()->id)->findOrFail($id);
    }

    private function assertMinor(string $dateOfBirth): void
    {
        $age = (int) Carbon::parse($dateOfBirth)->diffInYears(now());
        if ($age >= (int) config('akilil.adult_age')) {
            throw ValidationException::withMessages([
                'date_of_birth' => ['Dependents are under 18. Adults create their own account.'],
            ]);
        }
    }

    private function present(Dependent $d): array
    {
        return [
            'id'            => $d->id,
            'name'          => $d->name,
            'date_of_birth' => $d->date_of_birth->toDateString(),
            'age'           => $d->age(),
            'age_group'     => $d->ageGroup(),
            'gender'        => $d->gender,
            'relationship'  => $d->relationship,
            'care_notes'    => $d->care_notes,
            'has_teen_login' => (bool) $d->linked_user_id,
            'can_have_teen_login' => $d->age() >= (int) config('akilil.teen_login_min_age'),
            'consent_accepted_at' => $d->consent_accepted_at?->toIso8601String(),
        ];
    }
}
