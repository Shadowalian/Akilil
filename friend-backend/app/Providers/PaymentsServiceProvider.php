<?php

namespace App\Providers;

use App\Services\Payments\FakeGateway;
use App\Services\Payments\PaymentGateway;
use App\Services\Payments\StripeGateway;
use App\Services\Payments\UnconfiguredGateway;
use Illuminate\Support\ServiceProvider;

class PaymentsServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        $this->app->singleton(PaymentGateway::class, function () {
            $secret = (string) config('services.stripe.secret');
            $webhook = (string) config('services.stripe.webhook_secret');
            $configured = $secret !== '' && $webhook !== '';

            // The test gateway only ever runs on a developer machine or in
            // the test suite. Anywhere else, missing keys fail closed.
            if ($this->app->environment(['local', 'testing'])
                && (! $configured || config('akilil.payment_fake'))) {
                return new FakeGateway();
            }
            if (! $configured) {
                return new UnconfiguredGateway();
            }
            return new StripeGateway($secret, $webhook);
        });
    }
}