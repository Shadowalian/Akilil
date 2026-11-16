<?php

namespace App\Providers;

use App\Services\Payments\FakeGateway;
use App\Services\Payments\PaymentGateway;
use App\Services\Payments\StripeGateway;
use Illuminate\Support\ServiceProvider;

class PaymentsServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        $this->app->singleton(PaymentGateway::class, function () {
            $secret = (string) env('STRIPE_SECRET');
            $webhook = (string) env('STRIPE_WEBHOOK_SECRET');
            if ($secret === '' || $webhook === '' || env('FRIEND_PAYMENT_FAKE') === '1') {
                return new FakeGateway();
            }
            return new StripeGateway($secret, $webhook);
        });
    }
}