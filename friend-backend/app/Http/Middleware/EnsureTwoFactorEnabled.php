<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/**
 * Enforces that any user with an admin-side Spatie role (admin,
 * support, moderator) MUST have a confirmed TOTP secret before the
 * request is allowed to proceed.
 *
 * Used to gate sensitive management surfaces — including the Filament
 * admin panel (Task 6) and any future admin-only API endpoints. The
 * 2FA setup itself is reachable for un-set-up users via the
 * /api/auth/2fa/setup route, which is excluded from this gate.
 *
 * Per the brief: "2FA support (TOTP) as an optional enable/disable
 * flow for users, and enforce it for admin accounts (build the
 * enforcement hook now even though the admin panel comes in a later
 * task)" — this middleware is that hook.
 */
class EnsureTwoFactorEnabled
{
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();
        if (! $user) {
            return $next($request);
        }

        if (method_exists($user, 'hasAnyRole')
            && $user->hasAnyRole(['admin', 'support', 'moderator'])
            && ! (bool) $user->totp_enabled) {
            return response()->json([
                'error' => 'two_factor_required',
                'message' => 'Two-factor authentication must be set up before using admin features.',
                'setup_url' => '/api/auth/2fa/setup',
            ], 423);   // 423 Locked — distinct from 401 to drive UX correctly.
        }

        return $next($request);
    }
}
