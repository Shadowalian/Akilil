<?php

namespace App\Providers;

use App\Models\JournalEntry;
use App\Models\Message;
use App\Models\Vent;
use App\Observers\JournalEntryObserver;
use App\Observers\MessageObserver;
use App\Observers\VentObserver;
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

        // Crisis-detection pipeline observers (Task 5).
        JournalEntry::observe(JournalEntryObserver::class);
        Vent::observe(VentObserver::class);
        Message::observe(MessageObserver::class);
    }
}
