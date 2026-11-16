<?php

namespace Database\Seeders;

use App\Models\Category;
use App\Models\Gift;
use App\Models\Specialty;
use Illuminate\Database\Seeder;

/**
 * Reference data the product needs in every environment, production
 * included: the three pillars, their specialties, and the gift catalogue.
 * Safe to re-run.
 *
 *   php artisan db:seed --class=CatalogSeeder
 */
class CatalogSeeder extends Seeder
{
    public function run(): void
    {
        $pillars = [
            'spiritual-psychiatry' => [
                'name' => 'Spiritual Psychiatry',
                'description' => 'Faith-aware psychiatric care for mind and spirit.',
                'icon' => 'self_improvement',
                'specialties' => [
                    'Faith & anxiety', 'Grief & meaning', 'Mindful prayer',
                    'Premarital counselling', 'Marriage & couples (faith-based)',
                    'Family & parenting guidance', 'Youth mentoring',
                    'Spiritual direction', 'Forgiveness & reconciliation',
                ],
            ],
            'psychiatry' => [
                'name' => 'Psychiatry',
                'description' => 'Licensed clinical psychiatry and mental health support.',
                'icon' => 'psychology',
                'specialties' => [
                    'Depression', 'Anxiety disorders', 'Medication consult',
                    'Marriage & couples counselling', 'Premarital counselling',
                    'Family therapy', 'Child psychiatry', 'Adolescent & teen therapy',
                    'Parenting support', 'ADHD', 'Trauma & PTSD', 'Grief & loss',
                    'Addiction & recovery', 'Stress & burnout', 'Perinatal mental health',
                ],
            ],
            'cooking' => [
                'name' => 'Cooking',
                'description' => 'Live cooking classes and chef-led kitchen guidance.',
                'icon' => 'restaurant',
                'specialties' => [
                    'Plant-based', 'Weeknight meals', 'Baking basics',
                    'Ethiopian classics', 'Fasting dishes', 'Cooking with kids',
                    'Date-night cooking',
                ],
            ],
        ];

        $order = 0;
        foreach ($pillars as $slug => $pillar) {
            $category = Category::updateOrCreate(['slug' => $slug], [
                'name' => $pillar['name'],
                'description' => $pillar['description'],
                'icon' => $pillar['icon'],
                'sort_order' => $order++,
                'is_active' => true,
            ]);
            foreach ($pillar['specialties'] as $name) {
                Specialty::firstOrCreate(
                    ['category_id' => $category->id, 'slug' => str($name)->slug()->toString()],
                    ['name' => $name, 'is_active' => true],
                );
            }
        }

        // Prices are minor units of config('akilil.currency').
        $gifts = [
            ['slug' => 'coffee',   'name' => 'Buna',        'emoji' => '☕', 'price_cents' => 100,   'animation' => 'float'],
            ['slug' => 'rose',     'name' => 'Rose',        'emoji' => '🌹', 'price_cents' => 200,   'animation' => 'float'],
            ['slug' => 'candle',   'name' => 'Candle',      'emoji' => '🕯️', 'price_cents' => 300,   'animation' => 'float'],
            ['slug' => 'heart',    'name' => 'Heart',       'emoji' => '💛', 'price_cents' => 500,   'animation' => 'float'],
            ['slug' => 'injera',   'name' => 'Injera',      'emoji' => '🫓', 'price_cents' => 800,   'animation' => 'burst'],
            ['slug' => 'dove',     'name' => 'Dove',        'emoji' => '🕊️', 'price_cents' => 1500,  'animation' => 'burst'],
            ['slug' => 'chef-hat', 'name' => 'Chef\'s hat', 'emoji' => '👨‍🍳', 'price_cents' => 2500,  'animation' => 'burst'],
            ['slug' => 'crown',    'name' => 'Crown',       'emoji' => '👑', 'price_cents' => 5000,  'animation' => 'fullscreen'],
            ['slug' => 'lion',     'name' => 'Lion',        'emoji' => '🦁', 'price_cents' => 10000, 'animation' => 'fullscreen'],
        ];
        foreach ($gifts as $i => $gift) {
            Gift::updateOrCreate(['slug' => $gift['slug']], [...$gift, 'sort_order' => $i, 'is_active' => true]);
        }
    }
}
