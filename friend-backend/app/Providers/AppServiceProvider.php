<?php

namespace App\Providers;

use App\Models\JournalEntry;
use App\Models\Message;
use App\Models\Vent;
use App\Observers\JournalEntryObserver;
use App\Observers\MessageObserver;
use App\Observers\VentObserver;
use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\Facades\URL;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        //
    }

    public function boot(): void
    {
        \Illuminate\Http\Resources\Json\JsonResource::withoutWrapping();

        // Generated links (password reset, storage URLs) must be https behind
        // the TLS-terminating proxy.
        if ($this->app->environment('production')) {
            URL::forceScheme('https');
        }

        // Slows password guessing against one account without locking out a
        // whole office that shares an IP.
        RateLimiter::for('login', function (Request $request) {
            $email = mb_strtolower((string) $request->input('email'));
            return Limit::perMinute(5)->by($email.'|'.$request->ip());
        });

        // Crisis-detection pipeline observers (Task 5).
        JournalEntry::observe(JournalEntryObserver::class);
        Vent::observe(VentObserver::class);
        Message::observe(MessageObserver::class);
    }
}
