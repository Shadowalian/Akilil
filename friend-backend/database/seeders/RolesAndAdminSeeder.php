<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Spatie\Permission\Models\Role;

/**
 * Seeds the Spatie roles used by Akilil's RBAC layer, plus a default
 * admin user. Tasks 6+ adds per-resource abilities.
 *
 * Roles (single source of truth — see ARCHITECTURE.md §Roles):
 *   - admin     : full panel access, including financial + crisis flags
 *   - support   : can view user data, sessions metadata; no destructive ops
 *   - moderator : community/content moderation only
 *
 * Run with: `php artisan db:seed --class=RolesAndAdminSeeder`
 */
class RolesAndAdminSeeder extends Seeder
{
    public function run(): void
    {
        // Wipe any existing role assignments to keep this idempotent.
        DB::table('model_has_roles')->delete();
        DB::table('roles')->delete();

        $roles = [
            'admin'     => 'Platform administrator',
            'support'   => 'Customer support staff',
            'moderator' => 'Community/content moderator',
            // End-user / professional roles are NOT roles here; they live
            // on users.role (Task 1 migration) so they don't go through
            // the admin-side RBAC pipeline.
        ];

        foreach ($roles as $name => $description) {
            Role::firstOrCreate(['name' => $name, 'guard_name' => 'web']);
        }

        // Optional: bootstrap admin user with sensible defaults. Password is
        // a flag — change on first login. The user can also create admins
        // through the /admin panel later (Task 6).
        $email = env('BOOTSTRAP_ADMIN_EMAIL', 'admin@akilil.app');
        $password = env('BOOTSTRAP_ADMIN_PASSWORD', 'changeme-9k2x');

        $admin = User::firstOrCreate(
            ['email' => $email],
            [
                'name'              => 'Akilil Admin',
                'password'          => Hash::make($password),
                'email_verified_at' => now(),
                // role column is added by Task 1 migration; setting it here
                // would race the schema. Role assignment via spatie works
                // without users.role, which is fine for now.
            ]
        );

        $admin->syncRoles(['admin']);

        $this->command->info(sprintf(
            'Bootstrapped admin: %s (password from BOOTSTRAP_ADMIN_PASSWORD or default)',
            $email
        ));
    }
}
