<?php

namespace Tests\Feature\Api\Payments;

use App\Models\User;
use App\Models\Wallet;
use App\Services\Payments\FakeGateway;
use App\Services\Payments\PaymentGateway;
use App\Services\Payments\UnconfiguredGateway;
use App\Providers\PaymentsServiceProvider;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/** Money must never move through the test gateway outside development. */
class PaymentSafetyTest extends TestCase
{
    use RefreshDatabase;

    private function gatewayIn(string $env): PaymentGateway
    {
        $this->app['env'] = $env;
        $this->app->forgetInstance(PaymentGateway::class);
        (new PaymentsServiceProvider($this->app))->register();
        return $this->app->make(PaymentGateway::class);
    }

    public function test_production_without_keys_fails_closed_instead_of_faking(): void
    {
        config(['services.stripe.secret' => '', 'services.stripe.webhook_secret' => '', 'akilil.payment_fake' => true]);
        $this->assertInstanceOf(UnconfiguredGateway::class, $this->gatewayIn('production'));
        $this->assertInstanceOf(FakeGateway::class, $this->gatewayIn('testing'));
    }

    public function test_top_up_in_production_without_keys_says_so_and_moves_no_money(): void
    {
        $user = User::factory()->create();
        Wallet::create(['user_id' => $user->id, 'currency' => 'USD', 'balance_cents' => 0]);
        config(['services.stripe.secret' => '', 'services.stripe.webhook_secret' => '']);
        $this->gatewayIn('production');

        $this->actingAs($user)->postJson('/api/wallet/topup', ['amount_cents' => 100000])
            ->assertStatus(503)
            ->assertJsonPath('message', 'Payments are not set up yet. Please try again later.');
        $this->assertSame(0, (int) Wallet::where('user_id', $user->id)->value('balance_cents'));
    }

    public function test_the_fake_confirm_endpoint_is_gone_outside_development_even_with_debug_on(): void
    {
        config(['app.debug' => true]);
        $this->app['env'] = 'production';
        $this->actingAs(User::factory()->create())
            ->postJson('/api/wallet/topup/fake_anything/confirm')
            ->assertNotFound();
    }

    public function test_demo_mode_cannot_be_switched_on_in_production(): void
    {
        $config = require base_path('config/akilil.php');
        putenv('APP_ENV=production'); putenv('AKILIL_DEMO_MODE=true');
        $_ENV['APP_ENV'] = 'production'; $_ENV['AKILIL_DEMO_MODE'] = 'true';
        $_SERVER['APP_ENV'] = 'production'; $_SERVER['AKILIL_DEMO_MODE'] = 'true';
        $config = require base_path('config/akilil.php');
        $this->assertFalse($config['demo_mode']);
        putenv('APP_ENV=testing'); putenv('AKILIL_DEMO_MODE');
        $_ENV['APP_ENV'] = $_SERVER['APP_ENV'] = 'testing';
        unset($_ENV['AKILIL_DEMO_MODE'], $_SERVER['AKILIL_DEMO_MODE']);
    }
}
