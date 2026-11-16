<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * One-to-many live broadcasts (spiritual teaching, live cooking) with a
 * comment / like / gift feed.
 */
return new class extends Migration {
    public function up(): void
    {
        Schema::create('live_streams', function (Blueprint $table) {
            $table->id();
            $table->foreignId('professional_user_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('category_id')->constrained('categories');
            $table->foreignId('recipe_id')->nullable()->constrained('recipes')->nullOnDelete();

            $table->string('title', 160);
            $table->text('description')->nullable();
            $table->string('cover_image_path', 512)->nullable();

            $table->string('status', 16)->default('scheduled');   // scheduled | live | ended | cancelled
            $table->dateTime('scheduled_at');
            $table->timestamp('started_at')->nullable();
            $table->timestamp('ended_at')->nullable();
            $table->string('room_name', 191)->nullable();

            $table->boolean('allow_comments')->default(true);
            $table->boolean('allow_gifts')->default(true);

            // Denormalised counters, cheap to read on the discover feed.
            $table->unsignedInteger('peak_viewers')->default(0);
            $table->unsignedInteger('total_viewers')->default(0);
            $table->unsignedInteger('likes_count')->default(0);
            $table->unsignedBigInteger('gifts_total_cents')->default(0);

            $table->timestamps();
            $table->softDeletes();

            $table->index(['status', 'scheduled_at'], 'live_status_at_idx');
            $table->index(['professional_user_id', 'status'], 'live_pro_status_idx');
        });

        Schema::create('live_stream_viewers', function (Blueprint $table) {
            $table->id();
            $table->foreignId('live_stream_id')->constrained('live_streams')->cascadeOnDelete();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->timestamp('joined_at')->nullable();
            $table->timestamp('last_seen_at')->nullable();
            $table->boolean('is_banned')->default(false);
            $table->timestamps();

            $table->unique(['live_stream_id', 'user_id'], 'live_viewer_unique');
            $table->index(['live_stream_id', 'last_seen_at'], 'live_viewer_seen_idx');
        });

        // Append-only feed. `id` doubles as the polling cursor.
        Schema::create('live_stream_events', function (Blueprint $table) {
            $table->id();
            $table->foreignId('live_stream_id')->constrained('live_streams')->cascadeOnDelete();
            $table->foreignId('user_id')->nullable()->constrained('users')->nullOnDelete();
            $table->string('type', 16);               // comment | gift | like | join | system
            $table->string('body', 500)->nullable();
            $table->json('payload')->nullable();
            $table->timestamp('removed_at')->nullable();
            $table->timestamps();

            $table->index(['live_stream_id', 'id'], 'live_event_cursor_idx');
        });

        Schema::create('gifts', function (Blueprint $table) {
            $table->id();
            $table->string('slug', 48)->unique();
            $table->string('name', 64);
            $table->string('emoji', 16);
            $table->unsignedInteger('price_cents');
            // How big the on-screen effect is: float < burst < fullscreen.
            $table->string('animation', 16)->default('float');
            $table->unsignedSmallInteger('sort_order')->default(0);
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });

        Schema::create('gift_transactions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('gift_id')->constrained('gifts');
            $table->foreignId('live_stream_id')->constrained('live_streams')->cascadeOnDelete();
            $table->foreignId('sender_user_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('recipient_user_id')->constrained('users')->cascadeOnDelete();
            $table->unsignedSmallInteger('quantity')->default(1);
            $table->unsignedInteger('unit_price_cents');
            $table->unsignedInteger('total_cents');
            $table->char('currency', 3);
            $table->foreignId('transaction_id')->nullable()->constrained('transactions')->nullOnDelete();
            $table->timestamps();

            $table->index(['live_stream_id', 'created_at']);
            $table->index(['sender_user_id', 'created_at']);
        });

        // A new ledger type for wallet debits that are gifts.
        // (transactions.type is an enum on MySQL; widen it to a string.)
        Schema::table('transactions', function (Blueprint $table) {
            $table->string('type', 24)->change();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('gift_transactions');
        Schema::dropIfExists('gifts');
        Schema::dropIfExists('live_stream_events');
        Schema::dropIfExists('live_stream_viewers');
        Schema::dropIfExists('live_streams');
    }
};
