<?php

namespace App\Filament\Pages;

use App\Filament\Widgets\RevenueChart;
use App\Filament\Widgets\SessionsChart;
use App\Filament\Widgets\StatsOverview;
use Filament\Pages\Dashboard as BaseDashboard;

class Dashboard extends BaseDashboard
{
    protected static ?string $navigationIcon = 'heroicon-o-squares-2x2';
    protected static ?int $navigationSort = 1;

    public function getColumns(): int|string|array { return 1; }

    public function getWidgets(): array
    {
        return [
            StatsOverview::class,
            SessionsChart::class,
            RevenueChart::class,
        ];
    }
}