<?php

namespace App\Filament\Widgets;

use App\Models\Appointment;
use App\Models\Transaction;
use App\Models\User;
use Filament\Widgets\ChartWidget;
use Illuminate\Support\Carbon;

/**
 * Bookings vs revenue — last 14 days, daily buckets.
 * Two series: appointment count (line) and revenue $ (line, second axis).
 */
class SessionsChart extends ChartWidget
{
    protected static ?string $heading = 'Bookings (last 14 days)';
    protected static ?int $sort = 2;

    protected function getData(): array
    {
        $start = Carbon::now()->subDays(13)->startOfDay();
        $end   = Carbon::now()->endOfDay();

        $appointments = Appointment::whereBetween('created_at', [$start, $end])
            ->selectRaw('DATE(created_at) as d, COUNT(*) as c')
            ->groupBy('d')->pluck('c', 'd');

        $revenue = Transaction::whereIn('status', ['succeeded'])
            ->whereIn('type', ['payment', 'subscription'])
            ->whereBetween('created_at', [$start, $end])
            ->selectRaw('DATE(created_at) as d, SUM(amount_cents) as c')
            ->groupBy('d')->pluck('c', 'd');

        $labels = [];
        $apptSeries  = [];
        $revenueSeries = [];
        for ($i = 13; $i >= 0; $i--) {
            $d   = Carbon::now()->subDays($i)->toDateString();
            $labels[]     = $d;
            $apptSeries[]  = (int) ($appointments[$d] ?? 0);
            $revenueSeries[] = (int) round(((int) ($revenue[$d] ?? 0)) / 100);
        }

        return [
            'datasets' => [
                ['label' => 'Bookings',  'data' => $apptSeries,    'borderColor' => '#1A9FC4', 'backgroundColor' => 'rgba(26,159,196,0.18)'],
                ['label' => 'Revenue $', 'data' => $revenueSeries, 'borderColor' => '#FE814B', 'backgroundColor' => 'rgba(254,129,75,0.18)', 'yAxisID' => 'y1'],
            ],
            'labels' => $labels,
        ];
    }

    protected function getType(): string { return 'line'; }

    protected function getOptions(): array
    {
        return [
            'scales' => [
                'y'    => ['position' => 'left',  'beginAtZero' => true, 'title' => ['display' => true, 'text' => 'Bookings']],
                'y1'   => ['position' => 'right', 'beginAtZero' => true, 'grid' => ['drawOnChartArea' => false], 'title' => ['display' => true, 'text' => 'Revenue $']],
            ],
        ];
    }
}