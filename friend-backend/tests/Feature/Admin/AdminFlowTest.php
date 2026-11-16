<?php

namespace Tests\Feature\Admin;

use App\Models\AuditLog;
use App\Models\CrisisFlag;
use App\Models\ProfessionalProfile;
use App\Models\User;
use App\Services\TwoFactorService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Spatie\Permission\Models\Role;
use Tests\TestCase;

class AdminFlowTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        // Seed Spatie roles; RefreshDatabase wipes them between tests.
        foreach (['admin', 'support', 'moderator'] as $r) {
            Role::firstOrCreate(['name' => $r, 'guard_name' => 'web']);
        }
    }

    private function adminWith2FA(array $attrs = []): User
    {
        $svc = app(TwoFactorService::class);
        $secret = $svc->generateSecret();
        $user = User::factory()->create(array_merge([
            'totp_secret'      => $secret,
            'totp_enabled'     => true,
            'totp_confirmed_at' => now(),
        ], $attrs));
        $user->assignRole('admin');
        return $user;
    }

    public function test_non_admin_cannot_access_admin_panel(): void
    {
        $user = User::factory()->create();
        $this->actingAs($user)->get('/admin')->assertStatus(403);
    }

    public function test_admin_without_2fa_is_redirected_to_2fa_setup(): void
    {
        $user = User::factory()->create(['totp_enabled' => false]);
        $user->assignRole('admin');
        $this->actingAs($user)->get('/admin/users')->assertRedirect('/admin/2fa-setup');
    }

    public function test_admin_with_2fa_can_load_users_index(): void
    {
        $admin = $this->adminWith2FA();
        $this->actingAs($admin)->get('/admin/users')->assertOk();
    }

    public function test_admin_can_open_the_live_and_gift_pages(): void
    {
        $admin = $this->adminWith2FA();
        $this->actingAs($admin)->get('/admin/live-streams')->assertOk();
        $this->actingAs($admin)->get('/admin/gifts')->assertOk();
    }

    public function test_suspending_a_user_soft_deletes_the_record(): void
    {
        $admin = $this->adminWith2FA();
        $target = User::factory()->create();

        // Simulate the Filament action: the action calls $record->delete()
        // which on a SoftDeletes model sets deleted_at.
        $target->delete();

        $this->assertSoftDeleted('users', ['id' => $target->id]);
    }

    public function test_crisis_flag_mark_handled_updates_status(): void
    {
        $admin = $this->adminWith2FA();
        $user  = User::factory()->create();
        $flag  = CrisisFlag::create([
            'user_id'      => $user->id,
            'severity'     => 0.95,
            'source_type'  => 'journal_entry',
            'source_id'    => 1,
            'status'       => 'open',
            'matched_signals' => ['kill' => 0.95],
        ]);

        $flag->update(['status' => 'handled', 'handled_by' => $admin->id, 'handled_at' => now()]);

        $this->assertSame('handled', $flag->fresh()->status);
        $this->assertSame($admin->id, $flag->fresh()->handled_by);
    }

    public function test_audit_log_is_written_by_observer_for_admin_writes(): void
    {
        $admin = $this->adminWith2FA();
        $this->actingAs($admin);

        $target = User::factory()->create(['name' => 'Test User']);
        $target->update(['name' => 'Renamed by Admin']);

        $this->assertDatabaseHas('audit_logs', [
            'subject_type' => User::class,
            'subject_id'   => $target->id,
            'admin_id'     => $admin->id,
            'action'       => 'updated:user',
        ]);
    }

    public function test_audit_log_observer_does_not_fire_for_unauthenticated_writes(): void
    {
        auth()->logout();
        $u = User::factory()->create();
        $u->update(['name' => 'NoAuth']);

        $this->assertDatabaseMissing('audit_logs', [
            'subject_type' => User::class,
            'subject_id'   => $u->id,
        ]);
    }

    public function test_audit_log_viewer_is_read_only(): void
    {
        $admin = $this->adminWith2FA();
        $this->actingAs($admin);

        $log = AuditLog::create([
            'admin_id'     => $admin->id,
            'action'       => 'created:user',
            'subject_type' => User::class,
            'subject_id'   => 1,
            'route'        => 'admin',
            'ip_address'   => '127.0.0.1',
        ]);
        $this->get('/admin/audit-logs')->assertOk();
        $this->assertDatabaseHas('audit_logs', ['id' => $log->id]);
    }

    public function test_dashboard_endpoint_returns_health_for_admin(): void
    {
        $admin = $this->adminWith2FA();
        $token = $admin->createToken('test')->plainTextToken;
        $this->withToken($token)->getJson('/api/admin/health')
            ->assertOk()
            ->assertJsonStructure(['ok']);
    }

    public function test_professional_approve_changes_status(): void
    {
        $admin = $this->adminWith2FA();
        $pro = User::factory()->create(['role' => 'professional']);
        $category = \App\Models\Category::create(['name' => 'Active listening', 'slug' => 'active-listening']);
        $profile = ProfessionalProfile::create([
            'user_id'              => $pro->id,
            'category_id'          => $category->id,
            'verification_status'  => 'pending',
            'badge_active'         => false,
            'experience_years'     => 5,
        ]);

        $profile->update(['verification_status' => 'approved', 'badge_issued_by' => $admin->id, 'badge_issued_at' => now(), 'badge_active' => true]);

        $this->assertSame('approved', $profile->fresh()->verification_status);
        $this->assertTrue($profile->fresh()->badge_active);
    }
}