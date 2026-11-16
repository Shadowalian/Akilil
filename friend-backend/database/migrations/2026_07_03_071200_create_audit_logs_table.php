<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Admin-action audit trail. Written via Task 6's AuditObserver pattern
 * — every admin write goes through the observer so this table captures
 * the diff + identity + IP.
 *
 * subject_type + subject_id is polymorphic across any model the admin
 * touches (users, professionals, appointments, payouts, crisis_flags).
 */
return new class extends Migration {
    public function up(): void
    {
        Schema::create('audit_logs', function (Blueprint $table) {
            $table->id();
            $table->foreignId('admin_id')->constrained('users');    // the actor
            $table->string('action', 64);                          // 'update_verification', 'refund', etc.
            $table->morphs('subject');
            $table->json('before')->nullable();
            $table->json('after')->nullable();
            $table->string('ip_address', 45)->nullable();           // IPv6 ready
            $table->string('user_agent', 512)->nullable();
            $table->string('route', 191)->nullable();
            $table->timestamp('created_at')->useCurrent();
            $table->index(['admin_id', 'created_at'], 'audit_admin_created_idx');
            $table->index(['action', 'created_at'], 'audit_action_created_idx');
        });
    }
    public function down(): void { Schema::dropIfExists('audit_logs'); }
};