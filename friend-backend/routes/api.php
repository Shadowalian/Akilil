<?php

/**
 * Akilil API — version 1.
 *
 * Auth flow follows the spec in Task 2:
 *   - register / register-professional / login / logout
 *   - forgot-password / reset-password / verify-email
 *   - 2FA setup/confirm/disable/challenge (optional for users, REQUIRED for admin)
 *   - /me (GET/PUT) + /me/professional-profile
 *   - /professionals/onboarding/* — document upload + status
 *
 * Rate limits (beta-friendly): login/register 60/min, password reset 20/min.
 * Tight 5/min locked users out of private beta during normal retries.
 * /me uses the default 'api' throttle (60/min/user).
 */

use App\Http\Controllers\Api\Auth\EmailVerificationController;
use App\Http\Controllers\Api\Auth\LoginController;
use App\Http\Controllers\Api\Auth\LogoutController;
use App\Http\Controllers\Api\Auth\PasswordController;
use App\Http\Controllers\Api\Auth\RegisterController;
use App\Http\Controllers\Api\Auth\RegisterProfessionalController;
use App\Http\Controllers\Api\Auth\TwoFactorController;
use App\Http\Controllers\Api\Community\ChannelController;
use App\Http\Controllers\Api\Community\PostController;
use App\Http\Controllers\Api\Community\ReportController;
use App\Http\Controllers\Api\DeviceController;
use App\Http\Controllers\Api\LookupController;
use App\Http\Controllers\Api\MediaController;
use App\Http\Controllers\Api\MeController;
use App\Http\Controllers\Api\Messaging\ConversationController;
use App\Http\Controllers\Api\Messaging\MessageController;
use App\Http\Controllers\Api\NotificationController;
use App\Http\Controllers\Api\RatingController;
use App\Http\Controllers\Api\Professional\AvailabilityController;
use App\Http\Controllers\Api\Professional\ClientController;
use App\Http\Controllers\Api\Professional\EarningsController;
use App\Http\Controllers\Api\Professional\OnboardingController;
use App\Http\Controllers\Api\Professional\PayoutController;
use App\Http\Controllers\Api\Professional\ProAppointmentController;
use App\Http\Controllers\Api\Appointment\AppointmentController;
use App\Http\Controllers\Api\Appointment\ListeningRequestController;
use App\Http\Controllers\Api\Appointment\TestCallController;
use App\Http\Controllers\Api\TherapyGroup\TherapyGroupController;
use App\Http\Controllers\Api\TherapyGroup\TherapyGroupMeetingController;
use App\Http\Controllers\Api\TherapyGroup\TherapyGroupMemberController;
use App\Http\Controllers\Api\ProfessionalController;
use App\Http\Controllers\Api\Session\SessionController;
use App\Http\Controllers\Api\Session\SessionNoteController;
use App\Http\Controllers\Api\Webhook\JitsiWebhookController;
use App\Http\Controllers\Api\Wellness\GoalController;
use App\Http\Controllers\Api\Wellness\HabitController;
use App\Http\Controllers\Api\Wellness\JournalController;
use App\Http\Controllers\Api\Wellness\MoodController;
use App\Http\Controllers\Api\Wellness\VentController;
use App\Models\Message;
use Illuminate\Support\Facades\Route;

/* ---- Public auth endpoints ---- */
Route::middleware('throttle:60,1')->group(function () {
    Route::post('auth/register',              RegisterController::class)->name('auth.register');
    Route::post('auth/register-professional', RegisterProfessionalController::class)->name('auth.register-professional');
    Route::post('auth/login',                 LoginController::class)->name('auth.login');
});

Route::middleware('throttle:20,1')->group(function () {
    Route::post('auth/forgot-password', [PasswordController::class, 'sendLink'])->name('auth.forgot');
    Route::post('auth/reset-password',  [PasswordController::class, 'reset'])->name('auth.reset');
});

Route::post('auth/2fa/challenge', [TwoFactorController::class, 'challenge'])
    ->middleware('throttle:20,1')
    ->name('auth.2fa.challenge');

/* Lookups are public — pickers need them without a token */
Route::middleware('throttle:120,1')->group(function () {
    Route::get('categories',  [LookupController::class, 'categories'])->name('lookups.categories');
    Route::get('specialties', [LookupController::class, 'specialties'])->name('lookups.specialties');
    Route::get('languages',   [LookupController::class, 'languages'])->name('lookups.languages');
});

/* ---- Authenticated endpoints ---- */
Route::middleware(['auth:sanctum'])->group(function () {
    Route::post('auth/logout',              [LogoutController::class, 'current'])->name('auth.logout');
    Route::post('auth/logout-everywhere',   [LogoutController::class, 'everywhere'])->name('auth.logout-all');

    Route::post('auth/verify-email',                  [EmailVerificationController::class, 'verify'])->name('auth.verify-email');
    Route::post('auth/resend-verification',           [EmailVerificationController::class, 'resend'])->name('auth.resend-verification');

    /* 2FA — set up, confirm, disable */
    Route::post('auth/2fa/setup',   [TwoFactorController::class, 'setup'])->name('auth.2fa.setup');
    Route::post('auth/2fa/confirm', [TwoFactorController::class, 'confirm'])->name('auth.2fa.confirm');
    Route::post('auth/2fa/disable', [TwoFactorController::class, 'disable'])->name('auth.2fa.disable');

    /* /me + profile */
    Route::get('me',                  [MeController::class, 'show'])->name('me.show');
    Route::put('me',                  [MeController::class, 'update'])->name('me.update');
    Route::get('me/professional-profile', [MeController::class, 'professionalProfile'])->name('me.professional-profile');
    Route::put('me/professional-profile', [MeController::class, 'updateProfessionalProfile'])->name('me.professional-profile.update');

    /* Professional onboarding */
    Route::prefix('professionals/onboarding')->name('professionals.onboarding.')->group(function () {
        Route::get('status',                  [OnboardingController::class, 'status'])->name('status');
        Route::post('documents',              [OnboardingController::class, 'upload'])->name('documents.upload');
        Route::delete('documents/{id}',       [OnboardingController::class, 'destroy'])->name('documents.destroy');
    });

    /* Discovery — public read of professional profiles (auth still required for full details) */
    Route::get('professionals',                   [ProfessionalController::class, 'index'])->name('professionals.index');
    Route::get('professionals/recommended',       [ProfessionalController::class, 'index'])->defaults('sort', 'match')->name('professionals.recommended');
    Route::get('professionals/{id}',               [ProfessionalController::class, 'show'])->name('professionals.show');
    Route::get('professionals/{id}/available-slots', [AvailabilityController::class, 'availableSlots'])->name('professionals.slots');

    /* Professional availability management */
    Route::prefix('professional/availability')->name('professional.availability.')->group(function () {
        Route::get('/',                           [AvailabilityController::class, 'index'])->name('index');
        Route::get('blocks',                      [AvailabilityController::class, 'indexBlocks'])->name('blocks.index');
        Route::post('rules',                      [AvailabilityController::class, 'storeRule'])->name('rules.store');
        Route::put('rules/{id}',                  [AvailabilityController::class, 'updateRule'])->name('rules.update');
        Route::delete('rules/{id}',               [AvailabilityController::class, 'destroyRule'])->name('rules.destroy');
        Route::post('blocks',                     [AvailabilityController::class, 'storeBlock'])->name('blocks.store');
        Route::delete('blocks/{id}',              [AvailabilityController::class, 'destroyBlock'])->name('blocks.destroy');
    });

    /* Professional workspace — agenda, clients, money */
    Route::get('professional/appointments',      [ProAppointmentController::class, 'index'])->name('professional.appointments.index');
    Route::get('professional/clients',           [ClientController::class, 'index'])->name('professional.clients.index');
    Route::get('professional/earnings/summary',  [EarningsController::class, 'summary'])->name('professional.earnings.summary');
    Route::get('professional/payouts',           [PayoutController::class, 'index'])->name('professional.payouts.index');
    Route::post('professional/payouts',          [PayoutController::class, 'store'])->name('professional.payouts.store');

    /* Appointments */
    Route::get('appointments',                  [AppointmentController::class, 'index'])->name('appointments.index');
    Route::post('appointments',                 [AppointmentController::class, 'store'])->name('appointments.store');
    Route::post('appointments/test-call',       TestCallController::class)->name('appointments.test-call');
    Route::post('appointments/listening-request', [ListeningRequestController::class, 'store'])->name('appointments.listening-request');
    Route::get('appointments/{id}',             [AppointmentController::class, 'show'])->name('appointments.show');
    Route::put('appointments/{id}/reschedule',  [AppointmentController::class, 'reschedule'])->name('appointments.reschedule');
    Route::put('appointments/{id}/cancel',      [AppointmentController::class, 'cancel'])->name('appointments.cancel');
    Route::post('appointments/{id}/accept',     [ListeningRequestController::class, 'accept'])->name('appointments.accept');
    Route::post('appointments/{id}/decline',    [ListeningRequestController::class, 'decline'])->name('appointments.decline');

    /* Therapy groups — multi-member rooms hosted by a professional */
    Route::get('therapy-groups',                [TherapyGroupController::class, 'index'])->name('therapy-groups.index');
    Route::post('therapy-groups',               [TherapyGroupController::class, 'store'])->name('therapy-groups.store');
    Route::get('therapy-groups/{id}',           [TherapyGroupController::class, 'show'])->name('therapy-groups.show');
    Route::put('therapy-groups/{id}',           [TherapyGroupController::class, 'update'])->name('therapy-groups.update');
    Route::post('therapy-groups/{id}/archive',  [TherapyGroupController::class, 'archive'])->name('therapy-groups.archive');
    Route::post('therapy-groups/{id}/join',     [TherapyGroupMemberController::class, 'join'])->name('therapy-groups.join');
    Route::post('therapy-groups/{id}/leave',    [TherapyGroupMemberController::class, 'leave'])->name('therapy-groups.leave');
    Route::get('therapy-groups/{id}/meetings',  [TherapyGroupMeetingController::class, 'index'])->name('therapy-groups.meetings.index');
    Route::post('therapy-groups/{id}/meetings', [TherapyGroupMeetingController::class, 'store'])->name('therapy-groups.meetings.store');
    Route::post('therapy-group-meetings/{id}/start', [TherapyGroupMeetingController::class, 'start'])->name('therapy-group-meetings.start');
    Route::post('therapy-group-meetings/{id}/join',  [TherapyGroupMeetingController::class, 'join'])->name('therapy-group-meetings.join');

    /* Sessions — Jitsi room lifecycle */
    Route::post('appointments/{id}/session/start', [SessionController::class, 'start'])->name('sessions.start');
    Route::post('appointments/{id}/session/end',   [SessionController::class, 'end'])->name('sessions.end');

    /* Session notes — private to the professional who ran the session */
    Route::get ('appointments/{id}/notes',        [SessionNoteController::class, 'index'])->name('session-notes.index');
    Route::post('appointments/{id}/notes',        [SessionNoteController::class, 'store'])->name('session-notes.store');

    /* Ratings & reviews — {id} on the read side is a professional_profiles.id */
    Route::post('appointments/{id}/reviews',      [RatingController::class, 'store'])->name('reviews.store');
    Route::get ('professionals/{id}/reviews',     [RatingController::class, 'index'])->name('reviews.index');

    /* Messaging */
    Route::get('conversations',                  [ConversationController::class, 'index'])->name('conversations.index');
    Route::post('conversations',                 [ConversationController::class, 'store'])->name('conversations.store');
    Route::get('conversations/{id}',             [ConversationController::class, 'show'])->name('conversations.show');
    Route::post('conversations/{id}/read',       [ConversationController::class, 'markRead'])->name('conversations.read');
    Route::get('conversations/{id}/messages',    [MessageController::class, 'index'])->name('messages.index');
    Route::post('conversations/{id}/messages',   [MessageController::class, 'store'])->name('messages.store');

    /* Community — channels, feed, moderation reports */
    Route::get ('community/channels',              [ChannelController::class, 'index'])->name('community.channels.index');
    Route::get ('community/channels/{id}',         [ChannelController::class, 'show'])->name('community.channels.show');
    Route::get ('community/channels/{id}/posts',   [PostController::class, 'index'])->name('community.posts.index');
    Route::post('community/channels/{id}/posts',   [PostController::class, 'store'])->name('community.posts.store');
    Route::post('community/posts/{id}/report',     [ReportController::class, 'store'])->name('community.reports.store');

    /* Notifications */
    Route::get ('notifications',                  [NotificationController::class, 'index'])->name('notifications.index');
    Route::get ('notifications/unread-count',     [NotificationController::class, 'unreadCount'])->name('notifications.unread-count');
    Route::post('notifications/{id}/read',        [NotificationController::class, 'markRead'])->name('notifications.read');

    /* Devices — push tokens */
    Route::post('device-tokens',                 [DeviceController::class, 'store'])->name('devices.store');
    Route::delete('device-tokens/{id}',          [DeviceController::class, 'destroy'])->name('devices.destroy');
    Route::post('device-tokens/{id}/deactivate', [DeviceController::class, 'deactivate'])->name('devices.deactivate');

    /* Wellness — journal, mood, goals, habits, vents (Task 5) */
    Route::get   ('journal-entries',              [JournalController::class, 'index'])->name('journal.index');
    Route::post  ('journal-entries',              [JournalController::class, 'store'])->name('journal.store');
    Route::get   ('journal-entries/{id}',         [JournalController::class, 'show'])->name('journal.show');
    Route::put   ('journal-entries/{id}',         [JournalController::class, 'update'])->name('journal.update');
    Route::delete('journal-entries/{id}',         [JournalController::class, 'destroy'])->name('journal.destroy');

    Route::post  ('mood-logs',                     [MoodController::class, 'store'])->name('mood-logs.store');
    Route::get   ('mood-logs',                     [MoodController::class, 'index'])->name('mood-logs.index');
    Route::get   ('mood-logs/analytics',           [MoodController::class, 'analytics'])->name('mood-logs.analytics');

    Route::get   ('goals',                         [GoalController::class, 'index'])->name('goals.index');
    Route::post  ('goals',                         [GoalController::class, 'store'])->name('goals.store');
    Route::put   ('goals/{id}',                    [GoalController::class, 'update'])->name('goals.update');
    Route::delete('goals/{id}',                    [GoalController::class, 'destroy'])->name('goals.destroy');

    Route::get   ('habits',                        [HabitController::class, 'index'])->name('habits.index');
    Route::post  ('habits',                        [HabitController::class, 'store'])->name('habits.store');
    Route::put   ('habits/{id}',                   [HabitController::class, 'update'])->name('habits.update');
    Route::delete('habits/{id}',                   [HabitController::class, 'destroy'])->name('habits.destroy');
    Route::post  ('habits/{id}/log',               [HabitController::class, 'log'])->name('habits.log');

    Route::get   ('vents',                         [VentController::class, 'index'])->name('vents.index');
    Route::post  ('vents',                         [VentController::class, 'store'])->name('vents.store');
    Route::delete('vents/{id}',                    [VentController::class, 'destroy'])->name('vents.destroy');

    /* Media — serves files from PRIVATE_DISK with per-file authorization. */
    Route::get('media/{path}', [MediaController::class, 'show'])
        ->where('path', '.*')->name('media.serve');
});

/* ---- Public webhooks (provider-signed) ---- */
Route::post('webhooks/jitsi', [JitsiWebhookController::class, 'handle'])
    ->name('webhooks.jitsi');
Route::post('webhooks/stripe', [\App\Http\Controllers\Api\Webhook\StripeWebhookController::class, 'handle'])
    ->name('webhooks.stripe');

/* ---- Authenticated wallet endpoints (Task 8) ---- */
Route::middleware(['auth:sanctum'])->prefix('wallet')->group(function () {
    Route::post('topup',              [\App\Http\Controllers\Api\WalletController::class, 'topup'])->name('wallet.topup');
    // Dev-only confirmation endpoint used by FakeGateway:
    Route::post('topup/{reference}/confirm', [\App\Http\Controllers\Api\WalletController::class, 'fakeConfirm'])
        ->name('wallet.topup.confirm');
});
Route::middleware(['auth:sanctum'])->prefix('me')->group(function () {
    Route::get('wallet',          [\App\Http\Controllers\Api\WalletController::class, 'show'])->name('me.wallet');
    Route::get('wallet/transactions', [\App\Http\Controllers\Api\WalletController::class, 'transactions'])->name('me.wallet.transactions');
});

/* ---- Admin-gated endpoints (require 2FA setup) ----
   These examples show the hook is wired. Task 6 will add the actual
   /admin/* Filament routes and lock them behind this middleware.    */
Route::middleware(['auth:sanctum', '2fa.enforced'])->prefix('admin')->name('admin.')->group(function () {
    Route::get('health', fn () => response()->json(['ok' => true]))->name('health');
});