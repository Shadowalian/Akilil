<?php

namespace Database\Seeders;

use App\Models\Category;
use App\Models\CommunityChannel;
use App\Models\Conversation;
use App\Models\ConversationParticipant;
use App\Models\Device;
use App\Models\JournalEntry;
use App\Models\Language;
use App\Models\Message;
use App\Models\MoodLog;
use App\Models\Specialty;
use App\Models\SubscriptionPlan;
use App\Models\User;
use App\Models\Wallet;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use Spatie\Permission\Models\Role;

/**
 * Demo dataset for Akilil — Task 1 deliverable.
 *
 *   - 3 Akilil pillars: Spiritual Psychiatry, Psychiatry, Cooking
 *   - specialties per pillar
 *   - 6 languages (English + 4 Ethiopian + Swahili)
 *   - 20 end users (role = 'user')
 *   - 3 admins/support/moderators
 *   - Wallets for every user, with starting balances
 *   - A few journal entries, mood logs, conversations
 *   - 3 subscription plans
 *
 * Does NOT seed factory professionals or appointments — those come from
 * real onboarding / booking flows.
 *
 * Run: `php artisan migrate:fresh --seed`
 */
class DemoDataSeeder extends Seeder
{
    public function run(): void
    {
        /* ---- 1. Roles (re-seed idempotently) ---- */
        $roleNames = [
            'admin'     => 'Platform administrator',
            'support'   => 'Customer support staff',
            'moderator' => 'Community/content moderator',
        ];
        foreach ($roleNames as $name => $desc) {
            Role::firstOrCreate(['name' => $name, 'guard_name' => 'web']);
        }

        /* ---- 2. Categories — Akilil's only three pillars ---- */
        Category::query()->update(['is_active' => false]);

        $categories = [
            [
                'slug' => 'spiritual-psychiatry',
                'name' => 'Spiritual Psychiatry',
                'description' => 'Faith-aware psychiatric care for mind and spirit.',
                'icon' => 'self_improvement',
            ],
            [
                'slug' => 'psychiatry',
                'name' => 'Psychiatry',
                'description' => 'Licensed clinical psychiatry and mental health support.',
                'icon' => 'psychology',
            ],
            [
                'slug' => 'cooking',
                'name' => 'Cooking',
                'description' => 'Live cooking classes and chef-led kitchen guidance.',
                'icon' => 'restaurant',
            ],
        ];
        foreach ($categories as $i => $c) {
            Category::updateOrCreate(
                ['slug' => $c['slug']],
                [
                    'name' => $c['name'],
                    'description' => $c['description'],
                    'icon' => $c['icon'],
                    'sort_order' => $i,
                    'is_active' => true,
                ]
            );
        }
        $cats = Category::where('is_active', true)->orderBy('sort_order')->get();

        /* ---- 3. Specialties (per pillar) ---- */
        $specPool = [
            'spiritual-psychiatry' => [
                'Faith & anxiety',
                'Grief & meaning',
                'Mindful prayer',
            ],
            'psychiatry' => [
                'Depression',
                'Anxiety disorders',
                'Medication consult',
            ],
            'cooking' => [
                'Plant-based',
                'Weeknight meals',
                'Baking basics',
            ],
        ];
        foreach ($cats as $cat) {
            foreach ($specPool[$cat->slug] ?? [] as $name) {
                Specialty::firstOrCreate(
                    [
                        'category_id' => $cat->id,
                        'slug' => str($name)->slug()->toString(),
                    ],
                    ['name' => $name, 'is_active' => true]
                );
            }
        }

        /* ---- 4. Languages ---- */
        $languages = [
            ['code' => 'en', 'name' => 'English'],
            ['code' => 'am', 'name' => 'Amharic'],
            ['code' => 'om', 'name' => 'Afaan Oromoo'],
            ['code' => 'ti', 'name' => 'Tigrinya'],
            ['code' => 'sw', 'name' => 'Kiswahili'],
            ['code' => 'fr', 'name' => 'French'],
        ];
        foreach ($languages as $l) {
            Language::firstOrCreate(['code' => $l['code']], array_merge($l, ['is_active' => true]));
        }

        /* ---- 5. Subscription plans ---- */
        $plans = [
            ['slug' => 'plus-monthly',  'name' => 'Akilil Plus',        'price_cents' => 999,  'interval' => 'monthly', 'trial_days' => 7,  'features' => ['priority booking','unlimited journal','no ads']],
            ['slug' => 'plus-yearly',   'name' => 'Akilil Plus Yearly', 'price_cents' => 9900, 'interval' => 'yearly',  'trial_days' => 7,  'features' => ['priority booking','unlimited journal','no ads','2 months free']],
            ['slug' => 'family-monthly','name' => 'Family',             'price_cents' => 1999, 'interval' => 'monthly', 'trial_days' => 0,  'features' => ['4 seats','shared journal']],
        ];
        foreach ($plans as $i => $p) {
            SubscriptionPlan::firstOrCreate(['slug' => $p['slug']], array_merge($p, [
                'currency'   => 'USD',
                'limits'     => ['sessions_per_month' => 4],
                'is_active'  => true,
                'sort_order' => $i,
            ]));
        }

        /* ---- 6. Admin / support / moderator users ---- */
        $admin = User::firstOrCreate(
            ['email' => 'admin@akilil.app'],
            [
                'name' => 'Akilil Admin',
                'password' => Hash::make('changeme-9k2x'),
                'email_verified_at' => now(),
                'role' => 'user',
                'timezone' => 'Africa/Nairobi',
            ]
        );
        $admin->syncRoles(['admin']);

        $support = User::firstOrCreate(
            ['email' => 'support@akilil.app'],
            ['name' => 'Akilil Support', 'password' => Hash::make('changeme-9k2x'), 'email_verified_at' => now(), 'role' => 'user', 'timezone' => 'UTC']
        );
        $support->syncRoles(['support']);

        $mod = User::firstOrCreate(
            ['email' => 'mod@akilil.app'],
            ['name' => 'Akilil Mod', 'password' => Hash::make('changeme-9k2x'), 'email_verified_at' => now(), 'role' => 'user', 'timezone' => 'UTC']
        );
        $mod->syncRoles(['moderator']);

        /* ---- 7. End users (20) ---- */
        $endUsers = User::factory()->count(20)->create();
        $endUsers->each(fn ($u) => Wallet::firstOrCreate(['user_id' => $u->id], ['currency' => 'USD', 'balance_cents' => 5000]));

        /* ---- 8. Devices for some users (so push notification tests have data) ---- */
        $endUsers->random(8)->each(fn ($u) => Device::factory()->create(['user_id' => $u->id]));

        /* ---- 9. Wellness features: journals, mood logs ---- */
        JournalEntry::factory()->count(40)->create(['user_id' => fn () => $endUsers->random()->id]);
        MoodLog::factory()->count(120)->create(['user_id' => fn () => $endUsers->random()->id]);

        /* ---- 10. A starter conversation between two users (for chat tests) ---- */
        if ($endUsers->count() >= 2) {
            $conv = Conversation::create([
                'type' => 'direct',
                'created_by' => $endUsers[0]->id,
                'last_message_at' => now(),
            ]);
            ConversationParticipant::create([
                'conversation_id' => $conv->id, 'user_id' => $endUsers[0]->id, 'joined_at' => now(),
            ]);
            ConversationParticipant::create([
                'conversation_id' => $conv->id, 'user_id' => $endUsers[1]->id, 'joined_at' => now(),
            ]);
            Message::factory()->count(8)->create([
                'conversation_id' => $conv->id,
                'sender_id' => fn () => fake()->randomElement([$endUsers[0]->id, $endUsers[1]->id]),
            ]);
        }

        /* ---- 11. Community channels (owned by the moderator) ---- */
        $channels = [
            ['slug' => 'anxiety-support',  'name' => 'Anxiety Support',   'channel_type' => 'support_circle',   'description' => 'A calm place to talk through anxious days.'],
            ['slug' => '30-day-movement', 'name' => '30-Day Movement',    'channel_type' => 'challenge',       'description' => 'Move a little every day for 30 days.'],
            ['slug' => 'discipline-talk', 'name' => 'Discipline Talk',    'channel_type' => 'discipline_talk', 'description' => 'Habits, focus, and showing up.'],
        ];
        foreach ($channels as $c) {
            CommunityChannel::firstOrCreate(['slug' => $c['slug']], array_merge($c, [
                'created_by' => $mod->id,
            ]));
        }

        $this->command->info('Demo data seeded: ' . User::count() . ' users (no factory professionals/appointments).');
    }
}
