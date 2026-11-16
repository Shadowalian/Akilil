<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Top-up transactions don't have a local polymorphic reference
 * (their reference is the gateway's session id, already in
 * gateway_reference). Drop the NOT NULL on reference_type so
 * these don't trip the constraint.
 *
 * Same for reference_id — topups set it null; refunds keep both
 * columns pointing at the original transaction.
 */
return new class extends Migration {
    public function up(): void
    {
        Schema::table('transactions', function (Blueprint $t) {
            $t->dropMorphs('reference');
        });
        Schema::table('transactions', function (Blueprint $t) {
            $t->string('reference_type')->nullable();
            $t->unsignedBigInteger('reference_id')->nullable();
            $t->index(['reference_type', 'reference_id']);
        });
    }

    public function down(): void
    {
        Schema::table('transactions', function (Blueprint $t) {
            $t->dropIndex(['reference_type', 'reference_id']);
            $t->dropColumn(['reference_type', 'reference_id']);
        });
        Schema::table('transactions', function (Blueprint $t) {
            $t->morphs('reference');
        });
    }
};