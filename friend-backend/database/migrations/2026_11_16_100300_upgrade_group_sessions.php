<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Group sessions become a paid, per-meeting product: a member reserves a
 * seat for each meeting. Groups belong to a pillar; cooking classes carry
 * a recipe.
 */
return new class extends Migration {
    public function up(): void
    {
        Schema::table('therapy_groups', function (Blueprint $table) {
            $table->foreignId('category_id')->nullable()->after('professional_user_id')
                  ->constrained('categories')->nullOnDelete();
            $table->unsignedTinyInteger('min_age')->default(18)->after('max_members');
        });

        Schema::table('therapy_group_meetings', function (Blueprint $table) {
            $table->unsignedInteger('price_cents')->default(0)->after('duration_minutes');
            $table->char('currency', 3)->default('USD')->after('price_cents');
            $table->foreignId('recipe_id')->nullable()->after('currency')
                  ->constrained('recipes')->nullOnDelete();
        });

        Schema::create('therapy_group_meeting_seats', function (Blueprint $table) {
            $table->id();
            $table->foreignId('therapy_group_meeting_id')->constrained('therapy_group_meetings')->cascadeOnDelete();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->string('status', 16)->default('reserved');   // reserved | cancelled | refunded
            $table->unsignedInteger('price_cents')->default(0);
            $table->char('currency', 3)->default('USD');
            $table->foreignId('transaction_id')->nullable()->constrained('transactions')->nullOnDelete();
            $table->timestamp('ingredients_confirmed_at')->nullable();
            $table->timestamp('joined_at')->nullable();
            $table->timestamps();

            $table->unique(['therapy_group_meeting_id', 'user_id'], 'tgm_seat_unique');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('therapy_group_meeting_seats');
        Schema::table('therapy_group_meetings', function (Blueprint $table) {
            $table->dropConstrainedForeignId('recipe_id');
            $table->dropColumn(['price_cents', 'currency']);
        });
        Schema::table('therapy_groups', function (Blueprint $table) {
            $table->dropConstrainedForeignId('category_id');
            $table->dropColumn('min_age');
        });
    }
};
