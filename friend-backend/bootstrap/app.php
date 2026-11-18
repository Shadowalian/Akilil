<?php

use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        api: __DIR__.'/../routes/api.php',
        commands: __DIR__.'/../routes/console.php',
        channels: __DIR__.'/../routes/channels.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware) {
        // Behind nginx / a load balancer: trust X-Forwarded-* so request()->ip()
        // and https detection are correct. TRUSTED_PROXIES narrows it.
        $middleware->trustProxies(at: env('TRUSTED_PROXIES', '*'));
        $middleware->api(prepend: [
            \App\Http\Middleware\LocalizeApiResponse::class,
        ]);
        $middleware->alias([
            '2fa.enforced' => \App\Http\Middleware\EnsureTwoFactorEnabled::class,
        ]);
    })
    ->withExceptions(function (Exceptions $exceptions) {
        // Payment provider problems are a temporary outage for the user, not
        // a server crash: answer 503 with a readable message.
        $exceptions->render(function (\App\Services\Payments\GatewayException $e, $request) {
            if ($request->expectsJson()) {
                return response()->json(['message' => $e->getMessage()], 503);
            }
        });
    })->create();
