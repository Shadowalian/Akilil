<?php

namespace Tests\Feature\Payments;

use App\Models\Transaction;
use App\Models\User;
use App\Models\Wallet;
use App\Services\Payments\FakeGateway;
use App\Services\WalletService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class PaymentFlowTest extends TestCase
{
    use RefreshDatabase;

    private function user(array $attrs = []): User
    {
        return User::factory()->create($attrs);
    }

    public function test_wallet_is_lazy_created_on_first_read(): void
    {
        $u = $this->user();
        $this->assertDatabaseMissing('wallets', ['user_id' => $u->id]);
        $token = $u->createToken('test')->plainTextToken;
        $this->withToken($token)->getJson('/api/me/wallet')
            ->assertOk()
            ->assertJson(['balance_cents' => 0]);
        $this->assertDatabaseHas('wallets', ['user_id' => $u->id]);
    }

    public function test_topup_creates_a_pending_transaction_and_returns_url(): void
    {
        $u = $this->user();
        $token = $u->createToken('test')->plainTextToken;
        $res = $this->withToken($token)->postJson('/api/wallet/topup', [
            'amount_cents' => 2500,
            'currency'     => 'USD',
        ])->assertStatus(201)->json();
        $this->assertNotEmpty($res['checkout_url']);
        $this->assertNotEmpty($res['reference']);
        $this->assertDatabaseHas('transactions', [
            'user_id'      => $u->id,
            'amount_cents' => 2500,
            'status'       => 'pending',
            'type'         => 'topup',
        ]);
    }

    public function test_fake_confirm_endpoint_completes_topup(): void
    {
        $u = $this->user();
        $token = $u->createToken('test')->plainTextToken;
        $res = $this->withToken($token)->postJson('/api/wallet/topup', [
            'amount_cents' => 1000,
        ])->json();
        $reference = $res['reference'];

        $this->withToken($token)
            ->postJson("/api/wallet/topup/{$reference}/confirm")
            ->assertOk()
            ->assertJson(['status' => 'succeeded']);

        $tx = Transaction::where('gateway_reference', $reference)->firstOrFail();
        $this->assertSame('succeeded', $tx->status);
        $this->assertSame(1000, $u->fresh()->wallets()->first()->balance_cents);
    }

    public function test_webhook_with_valid_signature_completes_topup(): void
    {
        $u = $this->user();
        $token = $u->createToken('test')->plainTextToken;
        $res = $this->withToken($token)->postJson('/api/wallet/topup', [
            'amount_cents' => 5000,
        ])->json();
        $reference = $res['reference'];

        // Swap the FakeGateway for a real StripeGateway so the
        // signature verification code path is exercised.
        $secret = 'test_webhook_secret';
        $this->app->forgetInstance(\App\Services\Payments\PaymentGateway::class);
        $this->app->singleton(\App\Services\Payments\PaymentGateway::class,
            fn () => new \App\Services\Payments\StripeGateway('sk_test_placeholder', $secret));

        $payload = json_encode([
            'type'   => 'checkout.session.completed',
            'data'   => ['object' => [
                'id'           => $reference,
                'amount_total' => 5000,
                'currency'     => 'usd',
                'metadata'     => ['user_id' => $u->id],
            ]],
        ]);
        $t = time();
        $signed = $t . '.' . $payload;
        $sig = hash_hmac('sha256', $signed, $secret);

        $this->call('POST', '/api/webhooks/stripe', [], [], [], [
            'HTTP_STRIPE_SIGNATURE' => "t={$t},v1={$sig}",
            'CONTENT_TYPE'          => 'application/json',
        ], $payload)
            ->assertOk()
            ->assertJson(['received' => true]);

        $this->assertSame(5000, $u->fresh()->wallets()->first()->balance_cents);
    }

    public function test_webhook_rejects_bad_signature(): void
    {
        $this->app->forgetInstance(\App\Services\Payments\PaymentGateway::class);
        $this->app->singleton(\App\Services\Payments\PaymentGateway::class,
            fn () => new \App\Services\Payments\StripeGateway('sk_test_placeholder', 'test_webhook_secret'));

        $payload = json_encode(['type' => 'checkout.session.completed', 'data' => ['object' => []]]);
        $this->call('POST', '/api/webhooks/stripe', [], [], [], [
            'HTTP_STRIPE_SIGNATURE' => 't=1,v1=invalid',
            'CONTENT_TYPE'          => 'application/json',
        ], $payload)
            ->assertStatus(400);
    }

    public function test_topup_validates_minimum_amount(): void
    {
        $u = $this->user();
        $token = $u->createToken('test')->plainTextToken;
        $this->withToken($token)->postJson('/api/wallet/topup', [
            'amount_cents' => 50, // below 100 minimum
        ])->assertStatus(422);
    }

    public function test_transactions_list_returns_user_transactions_only(): void
    {
        $me = $this->user();
        $other = $this->user();
        $svc = app(WalletService::class);
        $svc->beginTopup($me, 1000);
        $svc->beginTopup($other, 2000);

        $token = $me->createToken('test')->plainTextToken;
        $res = $this->withToken($token)->getJson('/api/me/wallet/transactions')->assertOk()->json();
        $this->assertCount(1, $res['data']);
        $this->assertSame($me->id, $res['data'][0]['user_id']);
    }

    public function test_complete_topup_is_idempotent(): void
    {
        $u = $this->user();
        $token = $u->createToken('test')->plainTextToken;
        $res = $this->withToken($token)->postJson('/api/wallet/topup', [
            'amount_cents' => 1500,
        ])->json();
        $reference = $res['reference'];

        // Hit confirm twice.
        $this->withToken($token)->postJson("/api/wallet/topup/{$reference}/confirm")->assertOk();
        $this->withToken($token)->postJson("/api/wallet/topup/{$reference}/confirm")->assertOk();

        // Wallet should only be credited once.
        $this->assertSame(1500, $u->fresh()->wallets()->first()->balance_cents);
    }

    public function test_debit_fails_with_insufficient_balance(): void
    {
        $u = $this->user();
        $svc = app(WalletService::class);
        // Create a wallet with a small balance, then try to debit more.
        $svc->walletFor($u, 'USD')->update(['balance_cents' => 50]);
        $this->expectException(\DomainException::class);
        $svc->debit($u, 100, 'USD', 'payment');
    }

    public function test_debit_succeeds_with_sufficient_balance(): void
    {
        $u = $this->user();
        $svc = app(WalletService::class);
        $res = $svc->beginTopup($u, 5000, 'USD');
        $svc->completeTopup($res['session']->reference);

        $svc->debit($u, 1500, 'USD', 'payment');

        $wallet = $u->fresh()->wallets()->first();
        $this->assertSame(3500, $wallet->balance_cents);
        $this->assertSame(1500, $wallet->lifetime_spent_cents);
    }
}