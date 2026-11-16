<?php

use App\Http\Controllers\Web\MarketingController;
use Illuminate\Support\Facades\Route;

// Task 12 — public marketing site. Blade + the shared Vite/Tailwind
// pipeline, rendering the same tokens as the apps and the admin panel.
Route::get('/', [MarketingController::class, 'home'])->name('home');

// Static content pages. The slug doubles as the view name and the route
// name; `defaults()` hands it to MarketingController::page().
$pages = [
    'how-it-works',
    'for-professionals',
    'pricing',
    'safety',
    'about',
    'contact',
    'download',
    'privacy',
    'terms',
];

foreach ($pages as $page) {
    Route::get("/{$page}", [MarketingController::class, 'page'])
        ->defaults('view', $page)
        ->name($page);
}

Route::post('/contact', [MarketingController::class, 'contact'])
    ->middleware('throttle:5,1')
    ->name('contact.send');

// Task 0.5 — design system preview. Review-only page used to confirm
// the web tokens render correctly before any real screen work (Task 6+).
Route::get('/design-system', function () {
    return view('design-system');
});
