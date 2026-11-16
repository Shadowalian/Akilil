<?php

namespace App\Filament\Widgets;

use App\Models\Transaction;
use Filament\Widgets\ChartWidget;
use Illuminate\Support\Carbon;

/**
 * 12-month rolling revenue trend from `transactions`.
 * Excludes refunds explicitly — refund volume is shown on
 * the Transactions page so the headline number is honest.
 */
class RevenueChart extends ChartWidget
{
    protected static ?string $heading = 'Revenue (last 12 months)';
    protected static ?int $sort = 3;

    protected function getData(): array
    {
        $labels  = [];
        $series  = [];

        for ($i = 11; $i >= 0; $i--) {
            $start = Carbon::now()->subMonths($i)->startOfMonth();
            $end   = Carbon::now()->subMonths($i)->endOfMonth();

            $cents = (int) Transaction::whereIn('status', ['succeeded'])
                ->whereIn('type', ['payment', 'subscription'])
                ->whereBetween('created_at', [$start, $end])
                ->sum('amount_cents');

            $labels[] = $start->format('M Y');
            $series[] = (int) round($cents / 100);
        }

        return [
            'datasets' => [
                [
                    'label'           => 'Revenue $',
                    'data'            => $series,
                    'backgroundColor' => '#1A9FC4',
                    'borderColor'     => '#1282A2',
                ],
            ],
            'labels' => $labels,
        ];
    }

    protected function getType(): string { return 'bar'; }
}