<?php

namespace App\Http\Controllers\Api\Safety;

use App\Http\Controllers\Controller;
use App\Models\Appointment;
use App\Models\SafetyPlan;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * The person's own safety plan, and read access for the professionals
 * they have booked (and safety staff, via the admin panel).
 */
class SafetyPlanController extends Controller
{
    /** GET /api/me/safety-plan */
    public function show(Request $request): JsonResponse
    {
        return response()->json($this->present($request->user()->safetyPlan));
    }

    /** PUT /api/me/safety-plan */
    public function update(Request $request): JsonResponse
    {
        $data = $request->validate([
            'warning_signs'   => ['present', 'array', 'max:30'],
            'warning_signs.*' => ['string', 'max:300'],
            'coping'          => ['present', 'array', 'max:30'],
            'coping.*'        => ['string', 'max:300'],
            'people'          => ['present', 'array', 'max:15'],
            'people.*.name'   => ['required', 'string', 'max:100'],
            'people.*.phone'  => ['nullable', 'string', 'max:32'],
            'environment'     => ['present', 'array', 'max:30'],
            'environment.*'   => ['string', 'max:300'],
        ]);

        $plan = SafetyPlan::updateOrCreate(['user_id' => $request->user()->id], ['plan' => $data]);

        return response()->json($this->present($plan));
    }

    /**
     * GET /api/professional/clients/{userId}/safety-plan
     * Only for a professional this person has booked.
     */
    public function forClient(Request $request, int $userId): JsonResponse
    {
        $pro = $request->user();
        abort_unless($pro->role === 'professional', 403);
        $isTheirClient = Appointment::where('professional_user_id', $pro->id)
            ->where(fn ($q) => $q->where('user_id', $userId)
                ->orWhereHas('dependent', fn ($d) => $d->where('linked_user_id', $userId)))
            ->exists();
        abort_unless($isTheirClient, 403, 'This person is not your client.');

        return response()->json($this->present(User::findOrFail($userId)->safetyPlan));
    }

    private function present(?SafetyPlan $plan): array
    {
        $p = $plan?->plan ?? [];

        return [
            'warning_signs' => $p['warning_signs'] ?? [],
            'coping'        => $p['coping'] ?? [],
            'people'        => $p['people'] ?? [],
            'environment'   => $p['environment'] ?? [],
            'updated_at'    => $plan?->updated_at?->toIso8601String(),
        ];
    }
}
