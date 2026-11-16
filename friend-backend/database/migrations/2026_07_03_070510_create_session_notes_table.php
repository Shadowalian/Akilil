<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Private notes a professional writes for a client after a session.
 * Private to the professional + the named client; never exposed via any
 * public/community surface. Encrypted at rest in Task 10.
 */
return new class extends Migration {
    public function up(): void
    {
        Schema::create('session_notes', function (Blueprint $table) {
            $table->id();
            $table->foreignId('appointment_id')->constrained('appointments')->cascadeOnDelete();
            $table->foreignId('professional_user_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('client_user_id')->constrained('users')->cascadeOnDelete();

            $table->text('notes');
            $table->json('action_items')->nullable();    // [{title, due, done}]
            $table->json('tags')->nullable();

            $table->timestamps();
            $table->index(['appointment_id', 'professional_user_id'], 'sn_appt_pro_idx');
        });
    }
    public function down(): void { Schema::dropIfExists('session_notes'); }
};