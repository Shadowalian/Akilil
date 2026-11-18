<?php

use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Schedule;

Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote');

// Task 5 — purge expired vents every 5 minutes.
Schedule::command('friend:vents:purge-expired')
    ->everyFiveMinutes()
    ->withoutOverlapping();

// Drop expired API tokens (lifetime set by SANCTUM_TOKEN_LIFETIME_MINUTES).
Schedule::command('sanctum:prune-expired --hours=24')->daily();
