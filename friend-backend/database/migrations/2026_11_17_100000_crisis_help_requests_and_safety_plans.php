<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Crisis flags can now also be raised by the person themselves (asking for
 * help, or a high-risk screener answer), and record how they want to be
 * reached and when staff reached them. Safety plans move to the server so
 * the person's professionals and the safety team can read them.
 */
return new class extends Migration {
    public function up(): void
    {
        Schema::table('crisis_flags', function (Blueprint $table) {
            // content (automatic text scan) | help_request | screener
            $table->string('kind', 16)->default('content')->after('user_id');
            $table->string('contact_phone', 32)->nullable()->after('matched_signals');
            $table->string('contact_method', 16)->nullable()->after('contact_phone'); // call | message
            $table->text('user_message')->nullable()->after('contact_method');         // encrypted cast
            $table->timestamp('contacted_at')->nullable()->after('handled_at');
            $table->index(['kind', 'status']);
        });

        Schema::create('safety_plans', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->unique()->constrained('users')->cascadeOnDelete();
            $table->text('plan');   // encrypted:array on the model
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('safety_plans');
        Schema::table('crisis_flags', function (Blueprint $table) {
            $table->dropIndex(['kind', 'status']);
            $table->dropColumn(['kind', 'contact_phone', 'contact_method', 'user_message', 'contacted_at']);
        });
    }
};
