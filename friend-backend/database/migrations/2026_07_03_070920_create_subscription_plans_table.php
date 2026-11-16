<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Subscription plans the platform sells — e.g. "Akilil Plus Monthly".
 * prices in minor units per period.
 */
return new class extends Migration {
    public function up(): void
    {
        Schema::create('subscription_plans', function (Blueprint $table) {
            $table->id();
            $table->string('slug', 64)->unique();
            $table->string('name', 128);
            $table->text('description')->nullable();
            $table->char('currency', 3)->default('USD');
            $table->unsignedInteger('price_cents');
            $table->enum('interval', ['monthly', 'quarterly', 'yearly'])->default('monthly');
            $table->unsignedSmallInteger('trial_days')->default(0);
            $table->json('features')->nullable();     // included feature flags
            $table->json('limits')->nullable();       // e.g. {"sessions_per_month": 4}
            $table->boolean('is_active')->default(true);
            $table->unsignedSmallInteger('sort_order')->default(0);
            $table->timestamps();
        });
    }
    public function down(): void { Schema::dropIfExists('subscription_plans'); }
};