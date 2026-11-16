<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;

/**
 * Default `php artisan db:seed` entry point.
 * Runs the role bootstrap + the full demo dataset (Task 1 deliverable).
 */
class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        $this->call([
            RolesAndAdminSeeder::class,
            DemoDataSeeder::class,
            // After the demo seeder, which resets the pillar list.
            CatalogSeeder::class,
        ]);
    }
}