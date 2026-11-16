<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Chef recipes. Every cooking session — 1:1, group class or live —
 * points at a published recipe so participants can shop beforehand.
 */
return new class extends Migration {
    public function up(): void
    {
        Schema::create('recipes', function (Blueprint $table) {
            $table->id();
            $table->foreignId('professional_user_id')->constrained('users')->cascadeOnDelete();
            $table->string('title', 160);
            $table->text('description')->nullable();
            $table->string('cuisine', 64)->nullable();
            $table->string('difficulty', 16)->default('easy');   // easy | medium | hard
            $table->unsignedSmallInteger('prep_minutes')->default(0);
            $table->unsignedSmallInteger('cook_minutes')->default(0);
            $table->unsignedSmallInteger('servings')->default(2);
            $table->string('cover_image_path', 512)->nullable();
            $table->json('dietary_tags')->nullable();   // ['vegan', 'fasting', ...]
            $table->json('allergens')->nullable();      // ['gluten', 'nuts', ...]
            $table->json('equipment')->nullable();      // ['mitad', 'large pot', ...]
            $table->string('status', 16)->default('draft');     // draft | published | archived
            $table->timestamp('published_at')->nullable();
            $table->timestamps();
            $table->softDeletes();

            $table->index(['professional_user_id', 'status'], 'recipes_pro_status_idx');
        });

        Schema::create('recipe_ingredients', function (Blueprint $table) {
            $table->id();
            $table->foreignId('recipe_id')->constrained('recipes')->cascadeOnDelete();
            $table->string('name', 160);
            $table->string('quantity', 32)->nullable();   // free text: "1/2", "2-3"
            $table->string('unit', 32)->nullable();
            $table->string('note', 255)->nullable();
            $table->string('substitute', 255)->nullable();
            $table->boolean('is_optional')->default(false);
            $table->unsignedSmallInteger('sort_order')->default(0);
            $table->timestamps();
            $table->index(['recipe_id', 'sort_order']);
        });

        Schema::create('recipe_steps', function (Blueprint $table) {
            $table->id();
            $table->foreignId('recipe_id')->constrained('recipes')->cascadeOnDelete();
            $table->unsignedSmallInteger('position');
            $table->text('instruction');
            $table->unsignedSmallInteger('duration_minutes')->nullable();
            $table->timestamps();
            $table->index(['recipe_id', 'position']);
        });

        // A participant's shopping list for one recipe (ticks are personal).
        Schema::create('ingredient_checklists', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('recipe_id')->constrained('recipes')->cascadeOnDelete();
            $table->json('checked_ingredient_ids')->nullable();
            $table->timestamps();
            $table->unique(['user_id', 'recipe_id']);
        });

        Schema::table('appointments', function (Blueprint $table) {
            $table->foreignId('recipe_id')->nullable()->after('professional_profile_id')
                  ->constrained('recipes')->nullOnDelete();
            // Client's "I have everything" confirmation before a cooking session.
            $table->timestamp('ingredients_confirmed_at')->nullable();
        });
    }

    public function down(): void
    {
        Schema::table('appointments', function (Blueprint $table) {
            $table->dropConstrainedForeignId('recipe_id');
            $table->dropColumn('ingredients_confirmed_at');
        });
        Schema::dropIfExists('ingredient_checklists');
        Schema::dropIfExists('recipe_steps');
        Schema::dropIfExists('recipe_ingredients');
        Schema::dropIfExists('recipes');
    }
};
