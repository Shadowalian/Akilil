<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * The client app offers chat, voice and video sessions; the column only
 * allowed video and voice, so booking a chat session failed validation.
 */
return new class extends Migration {
    public function up(): void
    {
        Schema::table('appointments', function (Blueprint $table) {
            $table->string('session_type', 16)->default('video')->change();
        });
    }

    public function down(): void
    {
        // Left as a string: narrowing back to an enum would reject chat rows.
    }
};
