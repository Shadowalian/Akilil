<?php

namespace Tests\Feature\Api\Safety;

use App\Models\CrisisFlag;
use App\Models\User;
use App\Notifications\CrisisEscalationNotification;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Notification;
use Spatie\Permission\Models\Role;
use Tests\Support\BuildsWorld;
use Tests\TestCase;

class SafetyTest extends TestCase
{
    use BuildsWorld, RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        // Roles must exist before anything warms Spatie's permission cache.
        foreach (['admin', 'support', 'moderator'] as $r) {
            Role::firstOrCreate(['name' => $r, 'guard_name' => 'web']);
        }
    }

    private function admin(): User
    {
        $a = User::factory()->create(['totp_enabled' => true]);
        $a->assignRole('admin');

        return $a;
    }

    public function test_asking_for_help_alerts_staff_with_how_to_reach_the_person(): void
    {
        Notification::fake();
        $admin = $this->admin();
        $me = $this->adult();

        $this->actingAs($me)->postJson('/api/crisis/alerts', [
            'reason' => 'asked_for_help', 'phone' => '+251911000000', 'contact_method' => 'call', 'message' => 'I am not okay',
        ])->assertCreated()->assertJsonPath('alert.state', 'waiting');

        Notification::assertSentTo($admin, CrisisEscalationNotification::class);
        $flag = CrisisFlag::firstOrFail();
        $this->assertSame(['help_request', '+251911000000', 'I am not okay'], [$flag->kind, $flag->contact_phone, $flag->user_message]);
        $this->assertSame('+251911000000', $me->fresh()->phone);

        // A second tap updates the same request rather than creating another.
        $this->actingAs($me)->postJson('/api/crisis/alerts', ['reason' => 'screener_self_harm'])->assertCreated();
        $this->assertSame(1, CrisisFlag::count());
        $this->assertSame('screener', CrisisFlag::first()->kind);

        // Staff logging the call shows up for the person.
        CrisisFlag::first()->update(['contacted_at' => now(), 'status' => 'in_review']);
        $this->actingAs($me)->getJson('/api/crisis/alerts/latest')->assertJsonPath('alert.state', 'in_progress');

        $this->actingAs($admin, 'web')->get('/admin/crisis-flags')->assertOk();
    }

    public function test_safety_plan_is_saved_and_readable_by_their_professional_only(): void
    {
        $me = $this->adult();
        $plan = [
            'warning_signs' => ['I stop answering calls'],
            'coping' => ['Walk'],
            'people' => [['name' => 'Mimi', 'phone' => '0911']],
            'environment' => [],
        ];
        $this->actingAs($me)->putJson('/api/me/safety-plan', $plan)->assertOk()->assertJsonPath('people.0.name', 'Mimi');
        $this->actingAs($me)->getJson('/api/me/safety-plan')->assertJsonPath('warning_signs.0', 'I stop answering calls');

        $mine = $this->pro();
        $other = $this->pro();
        $this->actingAs($me)->postJson('/api/appointments', ['professional_user_id' => $mine->id, 'scheduled_at' => $this->slot()])->assertCreated();

        $this->actingAs($mine)->getJson("/api/professional/clients/{$me->id}/safety-plan")->assertOk()->assertJsonPath('coping.0', 'Walk');
        $this->actingAs($other)->getJson("/api/professional/clients/{$me->id}/safety-plan")->assertForbidden();
        $this->actingAs($this->adult())->getJson("/api/professional/clients/{$me->id}/safety-plan")->assertForbidden();

        $admin = $this->admin();
        $this->actingAs($admin, 'web')->get('/admin/safety-plans')->assertOk();
    }
}
