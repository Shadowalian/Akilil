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
