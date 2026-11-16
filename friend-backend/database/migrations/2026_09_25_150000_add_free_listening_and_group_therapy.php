<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Free listening requests (client → pro accept) + multi group therapy.
 */
return new class extends Migration {
    public function up(): void
    {
        Schema::table('professional_profiles', function (Blueprint $table) {
            $table->boolean('offers_free_listening')->default(false)->after('is_accepting_clients');
        });

        Schema::table('appointments', function (Blueprint $table) {
            $table->string('kind', 32)->default('scheduled')->after('session_type');
            // scheduled | listening_request
            $table->string('client_note', 1000)->nullable()->after('cancellation_reason');
            $table->index(['professional_user_id', 'kind', 'status'], 'appt_pro_kind_status_idx');
        });

        Schema::create('therapy_groups', function (Blueprint $table) {
            $table->id();
            $table->foreignId('professional_user_id')->constrained('users')->cascadeOnDelete();
            $table->string('title', 160);
            $table->text('description')->nullable();
            $table->unsignedTinyInteger('max_members')->default(12);
            $table->boolean('is_open')->default(true);
            $table->unsignedInteger('price_cents')->default(0);
            $table->char('currency', 3)->default('USD');
            $table->enum('status', ['active', 'archived'])->default('active');
            $table->timestamps();
            $table->softDeletes();

            $table->index(['professional_user_id', 'status'], 'tg_pro_status_idx');
            $table->index(['is_open', 'status'], 'tg_open_status_idx');
        });

        Schema::create('therapy_group_members', function (Blueprint $table) {
            $table->id();
            $table->foreignId('therapy_group_id')->constrained('therapy_groups')->cascadeOnDelete();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->enum('status', ['active', 'left'])->default('active');
            $table->timestamp('joined_at')->useCurrent();
            $table->timestamps();

            $table->unique(['therapy_group_id', 'user_id'], 'tg_member_unique');
        });

        Schema::create('therapy_group_meetings', function (Blueprint $table) {
            $table->id();
            $table->foreignId('therapy_group_id')->constrained('therapy_groups')->cascadeOnDelete();
            $table->string('title', 160)->nullable();
            $table->dateTime('scheduled_at');
            $table->unsignedSmallInteger('duration_minutes')->default(60);
            $table->enum('status', ['scheduled', 'live', 'ended', 'cancelled'])->default('scheduled');
            $table->string('room_name', 191)->nullable();
            $table->timestamp('started_at')->nullable();
            $table->timestamp('ended_at')->nullable();
            $table->timestamps();

            $table->index(['therapy_group_id', 'scheduled_at'], 'tgm_group_at_idx');
            $table->index('status');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('therapy_group_meetings');
        Schema::dropIfExists('therapy_group_members');
        Schema::dropIfExists('therapy_groups');

        Schema::table('appointments', function (Blueprint $table) {
            $table->dropIndex('appt_pro_kind_status_idx');
            $table->dropColumn(['kind', 'client_note']);
        });

        Schema::table('professional_profiles', function (Blueprint $table) {
            $table->dropColumn('offers_free_listening');
        });
    }
};
