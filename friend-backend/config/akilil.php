<?php

/**
 * Akilil product rules — age gates, platform fees, cooking lead times,
 * live-stream policy. Everything here is a business decision, so it lives
 * in config (env-overridable) rather than scattered through controllers.
 */

return [

    /*
     * Demo conveniences (instant professional approval, the free
     * "test call" endpoint). Never enable in production: real
     * professionals must pass credential review before taking clients.
     */
    'demo_mode' => (bool) env('AKILIL_DEMO_MODE', false) && env('APP_ENV') !== 'production',

    // Development only: use the test payment gateway even if keys exist.
    'payment_fake' => env('FRIEND_PAYMENT_FAKE') === '1',

    /* ---- Age & family ---------------------------------------------- */

    // Adults sign themselves up. Anyone younger is added by a parent or
    // legal guardian as a dependent (see `dependents` table).
    'adult_age' => (int) env('AKILIL_ADULT_AGE', 18),

    // Teens at or above this age may get their own (guardian-managed)
    // login. Younger children attend on the guardian's device.
    'teen_login_min_age' => (int) env('AKILIL_TEEN_LOGIN_MIN_AGE', 13),

    // Bumped whenever the guardian consent wording changes, so we can tell
    // which text a guardian actually agreed to.
    'guardian_consent_version' => env('AKILIL_GUARDIAN_CONSENT_VERSION', '2026-11'),

    // Client age bands a professional can declare they serve.
    'age_groups' => [
        'children' => [0, 12],
        'teens'    => [13, 17],
        'adults'   => [18, 200],
    ],

    // How a session is delivered. `child`/`teen` formats require a
    // dependent; `couples`/`family` allow invited participants.
    'care_formats' => ['individual', 'couples', 'family', 'child', 'teen'],

    /* ---- Money ------------------------------------------------------ */

    // Single platform currency. Wallets, prices, gifts and payouts all use it.
    // Ethiopian birr unless the deployment says otherwise.
    'currency' => env('AKILIL_CURRENCY', 'ETB'),

    'fees' => [
        // Platform commission kept from each completed session / group seat.
        'session_percent' => (float) env('AKILIL_FEE_SESSION_PERCENT', 20),
        'group_percent'   => (float) env('AKILIL_FEE_GROUP_PERCENT', 20),
        // Commission kept from live gifts.
        'gift_percent'    => (float) env('AKILIL_FEE_GIFT_PERCENT', 30),
    ],

    /* ---- Cooking ---------------------------------------------------- */

    'cooking' => [
        'pillar' => 'cooking',
        // A cooking session (1:1, class, or live) must be on the calendar at
        // least this long before it starts so people can shop for the recipe.
        'min_lead_hours' => (int) env('AKILIL_COOKING_MIN_LEAD_HOURS', 24),
        // How early a chef may open the room before the scheduled time.
        'early_start_minutes' => 15,
    ],

    /* ---- Live streams & gifts -------------------------------------- */

    'live' => [
        // Only these pillars may broadcast. Clinical psychiatry is
        // deliberately excluded: treatment is private, never an audience.
        'pillars' => ['spiritual-psychiatry', 'cooking'],
        'viewer_min_age' => (int) env('AKILIL_LIVE_VIEWER_MIN_AGE', 13),
        // A viewer counts as "watching" if they polled within this window.
        'presence_window_seconds' => 25,
        'max_comment_length' => 300,
        'comments_per_minute' => 20,
    ],

    'gifts' => [
        // Sending gifts spends real money: adults only.
        'min_age' => (int) env('AKILIL_GIFT_MIN_AGE', 18),
        'max_quantity' => 99,
    ],
];
