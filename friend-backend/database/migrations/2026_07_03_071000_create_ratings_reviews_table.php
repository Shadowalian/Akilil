<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * User reviews after a completed session.
 * 1:1 with appointment; one rating per appointment; response_from_professional
 * is the pro's reply (single-shot, no edits).
 */
return new class extends Migration {
    public function up(): void
    {
        Schema::create('ratings_reviews', function (Blueprint $table) {
            $table->id();
            $table->foreignId('appointment_id')->unique()->constrained('appointments')->cascadeOnDelete();
            $table->foreignId('client_user_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('professional_user_id')->constrained('users')->cascadeOnDelete();

            $table->unsignedTinyInteger('rating');   // 1..5
            $table->text('comment')->nullable();
            $table->boolean('is_anonymous')->default(false);

            $table->text('response_from_professional')->nullable();
            $table->timestamp('response_at')->nullable();

            $table->enum('status', ['visible', 'hidden', 'reported', 'removed'])->default('visible');
            $table->timestamps();
            $table->softDeletes();

            $table->index(['professional_user_id', 'status', 'created_at'], 'rr_pro_status_created_idx');
        });
    }
    public function down(): void { Schema::dropIfExists('ratings_reviews'); }
};