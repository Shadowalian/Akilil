<?php

namespace App\Http\Controllers\Api\Professional;

use App\Http\Controllers\Controller;
use App\Models\Appointment;
use Carbon\CarbonImmutable;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class EarningsController extends Controller
{
    /** Sessions that count as money earned (or about to be). */
    private const EARNING_STATUSES = ['completed', 'in_progress', 'confirmed'];

    /**
     * GET /api/professional/earnings/summary?days=84
     * Gross earnings for the window plus a zero-filled daily series so the
     * Pro app can chart it without patching gaps client-side.
     */
    public function summary(Request $request): JsonResponse
    {
        $user = $request->user();
        abort_unless($user->role === 'professional', 403, 'Only professionals can view this.');

        $days  = max(1, min((int) $request->query('days', 84), 365));
        $start = CarbonImmutable::now()->startOfDay()->subDays($days - 1);

        $byDay = Appointment::query()
            ->where('professional_user_id', $user->id)
            ->whereIn('status', self::EARNING_STATUSES)
            ->where('scheduled_at', '>=', $start)
            ->selectRaw('DATE(scheduled_at) as day, SUM(price_cents) as cents')
            ->groupBy('day')
            ->pluck('cents', 'day');

        $series = [];
        $total  = 0;
        for ($i = 0; $i < $days; $i++) {
            $date  = $start->addDays($i)->toDateString();
            $cents = (int) ($byDay[$date] ?? 0);
            $total += $cents;
            $series[] = ['date' => $date, 'cents' => $cents];
        }

        return response()->json([
            'total_cents' => $total,
            'currency'    => $user->professionalProfile?->currency ?: 'USD',
            'series'      => $series,
        ]);
    }
}
