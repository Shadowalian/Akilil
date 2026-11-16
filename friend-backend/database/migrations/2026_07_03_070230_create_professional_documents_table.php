<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Documents a professional uploads for credential verification.
 * Stored on the PRIVATE_DISK (never `public`) — see .env.example.
 * review fields populated by admin/support in Task 6.
 */
return new class extends Migration {
    public function up(): void
    {
        Schema::create('professional_documents', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->enum('document_type', [
                'government_id',
                'professional_license',
                'degree',
                'certification',
                'background_check',
                'other',
            ]);
            $table->string('file_path', 512);                  // PRIVATE_DISK path
            $table->string('original_filename', 255);
            $table->unsignedInteger('size_bytes');
            $table->string('mime_type', 64);
            $table->string('description', 512)->nullable();

            $table->enum('review_status', [
                'pending',
                'in_review',
                'approved',
                'rejected',
                'reupload_required',
            ])->default('pending');
            $table->index('review_status');

            $table->foreignId('reviewed_by')->nullable()->constrained('users');
            $table->timestamp('reviewed_at')->nullable();
            $table->text('review_notes')->nullable();

            $table->timestamps();
            $table->index('user_id');
        });
    }
    public function down(): void { Schema::dropIfExists('professional_documents'); }
};