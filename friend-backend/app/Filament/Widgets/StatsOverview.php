<?php

namespace App\Filament\Widgets;

use App\Models\Appointment;
use App\Models\CallSession;
use App\Models\ProfessionalProfile;
use App\Models\Transaction;
use App\Models\User;
use Filament\Widgets\StatsOverviewWidget as BaseWidget;
use Filament\Widgets\StatsOverviewWidget\Stat;
use Illuminate\Support\Carbon;

/**
 * Headline numbers aligned with the Akilil apps: users, counselors, bookings, video.
 */
class StatsOverview extends BaseWidget
{
    protected static ?int $sort = 1;

    protected function getStats(): array
    {
        $now = Carbon::now();
        $thirtyAgo = $now->copy()->subDays(30);

        $usersTotal = User::where('role', 'user')->count();
        $usersNew = User::where('role', 'user')->where('created_at', '>=', $thirtyAgo)->count();
        $prosApproved = ProfessionalProfile::where('verification_status', 'approved')
            ->where('is_accepting_clients', true)
            ->count();
        $prosPending = ProfessionalProfile::where('verification_status', 'pending')->count();
        $apptUpcoming = Appointment::where('scheduled_at', '>=', $now)
            ->whereIn('status', ['confirmed', 'pending'])
            ->count();
        $apptInProgress = Appointment::where('status', 'in_progress')->count();
        $liveRooms = CallSession::where('status', 'active')->count();
        $apptLast30 = Appointment::where('created_at', '>=', $thirtyAgo)->count();
        $revenueCents30 = (int) Transaction::whereIn('status', ['succeeded'])
            ->whereIn('type', ['payment', 'subscription'])
            ->where('created_at', '>=', $thirtyAgo)
            ->sum('amount_cents');
        $topupsCents30 = (int) Transaction::where('status', 'succeeded')
            ->where('type', 'topup')
            ->where('created_at', '>=', $thirtyAgo)
            ->sum('amount_cents');

        return [
            Stat::make('Clients', number_format($usersTotal))
                ->description('+'.number_format($usersNew).' last 30d')
                ->descriptionIcon('heroicon-m-arrow-trending-up')
                ->color('success'),
            Stat::make('Live counselors', number_format($prosApproved))
                ->description(number_format($prosPending).' pending review')
                ->descriptionIcon('heroicon-m-user-circle')
                ->color($prosPending > 0 ? 'warning' : 'success'),
            Stat::make('Upcoming bookings', number_format($apptUpcoming))
                ->description(number_format($apptLast30).' booked in last 30d')
                ->descriptionIcon('heroicon-m-calendar-days')
                ->color('info'),
            Stat::make('Live video now', number_format($liveRooms))
                ->description(number_format($apptInProgress).' sessions in progress')
                ->descriptionIcon('heroicon-m-video-camera')
                ->color($liveRooms > 0 ? 'warning' : 'success'),
            Stat::make('Session revenue (30d)', '$'.number_format($revenueCents30 / 100, 2))
                ->description('Wallet top-ups: $'.number_format($topupsCents30 / 100, 2))
                ->color('success'),
        ];
    }
}
