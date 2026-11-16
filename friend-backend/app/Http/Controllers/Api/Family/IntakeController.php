<?php

namespace App\Http\Controllers\Api\Family;

use App\Http\Controllers\Controller;
use App\Models\Dependent;
use App\Models\IntakeResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * The matching questionnaire ("who is this for, what brings you here").
 * Its answers pre-filter discovery so a couple sees couples counsellors
 * and a parent sees people who work with their child's age group.
 */
class IntakeController extends Controller
{
    /** GET /api/intake — latest answers, or null. */
    public function show(Request $request): JsonResponse
    {
        $latest = IntakeResponse::where('user_id', $request->user()->id)->latest('id')->first();

        return response()->json(['intake' => $latest ? $this->present($latest) : null]);
    }

    /** POST /api/intake */
    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'pillar'       => ['nullable', 'string', 'exists:categories,slug'],
            'care_format'  => ['required', 'in:'.implode(',', config('akilil.care_formats'))],
            'dependent_id' => ['nullable', 'integer'],
            'answers'      => ['required', 'array', 'max:60'],
        ]);

        if (! empty($data['dependent_id'])) {
            abort_unless(
                Dependent::where('guardian_user_id', $request->user()->id)->whereKey($data['dependent_id'])->exists(),
                422,
                'Unknown dependent.'
            );
        }

        $intake = IntakeResponse::create([
            'user_id'      => $request->user()->id,
            'dependent_id' => $data['dependent_id'] ?? null,
            'pillar'       => $data['pillar'] ?? null,
            'care_format'  => $data['care_format'],
            'answers'      => $data['answers'],
        ]);

        return response()->json(['intake' => $this->present($intake)], 201);
    }

    private function present(IntakeResponse $i): array
    {
        return [
            'id'           => $i->id,
            'pillar'       => $i->pillar,
            'care_format'  => $i->care_format,
            'dependent_id' => $i->dependent_id,
            'answers'      => $i->answers,
            'created_at'   => $i->created_at?->toIso8601String(),
        ];
    }
}
