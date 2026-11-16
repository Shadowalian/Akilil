<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Crisis-detection flag from Task 5. ONE row per flagged event.
 * `source` is the polymorphic origin (journal, vent, message, chat).
 * `severity` is the heuristic score 0..1; admins act on the top band.
 *
 * CRITICAL: this is a harm-reduction feature, NOT a diagnostic tool.
 * Admin review is always the deciding step — see Task 5 docs.
 */
return new class extends Migration {
    public function up(): void
    {
        Schema::create('crisis_flags', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->morphs('source');                       // journal/vent/message

            $table->decimal('severity', 4, 3);              // 0.000 .. 1.000
            $table->json('matched_signals')->nullable();    // [{signal: 'keyword', value: '...'}]
            $table->enum('status', [
                'open',
                'in_review',
                'handled',
                'false_positive',
            ])->default('open');
            $table->index('status');

            $table->foreignId('handled_by')->nullable()->constrained('users');
            $table->timestamp('handled_at')->nullable();
            $table->text('handling_notes')->nullable();

            $table->timestamps();
            $table->index(['user_id', 'status', 'created_at'], 'crisis_user_status_created_idx');
        });
    }
    public function down(): void { Schema::dropIfExists('crisis_flags'); }
};