<?php

namespace App\Http\Controllers\Api\Professional;

use App\Http\Controllers\Controller;
use App\Models\Appointment;
use App\Models\Earning;
use App\Services\EarningsService;
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

        // The real ledger: net of platform fees, by source.
        $ledger = Earning::where('professional_user_id', $user->id)->where('status', 'available');
        $byKind = (clone $ledger)->selectRaw('kind, SUM(net_cents) as net, SUM(gross_cents) as gross')
            ->groupBy('kind')->get()->keyBy('kind');

        return response()->json([
            'available_cents' => app(EarningsService::class)->availableCents($user),
            'net_cents'       => (int) (clone $ledger)->sum('net_cents'),
            'fees_cents'      => (int) (clone $ledger)->sum('fee_cents'),
            'by_source'       => [
                'sessions' => (int) ($byKind['session']->net ?? 0),
                'groups'   => (int) ($byKind['group_seat']->net ?? 0),
                'gifts'    => (int) ($byKind['gift']->net ?? 0),
            ],
            'total_cents' => $total,
            'currency'    => $user->professionalProfile?->currency ?: config('akilil.currency'),
            'series'      => $series,
        ]);
    }
}
