<?php

namespace App\Http\Middleware;

use Closure;
use Filament\Notifications\Notification;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/**
 * PanelEnsureTwoFactorEnabled — Filament-flavored 2FA gate.
 *
 * Rejects admin/support/moderator users who don't have TOTP confirmed
 * and redirects them to /admin/2fa/setup with a friendly toast.
 *
 * Difference from the API-side EnsureTwoFactorEnabled middleware
 * (which returns 423 JSON): this one returns a redirect with a
 * Filament notification, which is the right UX for a web admin panel.
 *
 * Wired in AdminPanelProvider's auth middleware chain.
 */
class PanelEnsureTwoFactorEnabled
{
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();
        if (! $user) {
            return $next($request);
        }

        $isStaff = method_exists($user, 'hasAnyRole')
            && $user->hasAnyRole(['admin', 'support', 'moderator']);
        if (! $isStaff) {
            return $next($request);
        }

        if ((bool) $user->totp_enabled) {
            return $next($request);
        }

        // Don't trigger on the 2FA setup page itself (avoid loop).
        if ($request->routeIs('filament.admin.pages.2fa-setup')) {
            return $next($request);
        }

        Notification::make()
            ->title('Two-factor authentication is required')
            ->body('Please set up 2FA before accessing the admin panel.')
            ->danger()
            ->send();

        return redirect()->route('filament.admin.pages.2fa-setup');
    }
}