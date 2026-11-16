<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * In-app + push notifications.
 *
 * `notifiable` is morphs to the recipient (typically User but could be
 * another model in the future). `data` holds the render payload + push
 * payload (FCM/APNs). The Laravel Notification system (Task 4) is the
 * producer; this table is the durable record.
 *
 * `channel` tells us which delivery path this row represents so that
 * multi-channel dispatches produce multiple rows (one per channel).
 */
return new class extends Migration {
    public function up(): void
    {
        Schema::create('notifications', function (Blueprint $table) {
            $table->uuid('id')->primary();   // standard Laravel notification shape
            $table->string('type', 191);
            $table->morphs('notifiable');
            $table->json('data');
            $table->timestamp('read_at')->nullable();
            $table->timestamps();
            $table->index('read_at');

            // Per-channel delivery record (Task 4 broadcasts through Reverb,
            // FCM, APNs, and database channels).
            $table->enum('channel', ['database', 'broadcast', 'push', 'mail', 'sms'])
                  ->default('database');
            $table->enum('push_status', ['pending', 'sent', 'delivered', 'failed'])->nullable();
            $table->timestamp('pushed_at')->nullable();
            $table->text('failure_reason')->nullable();

            $table->index(['notifiable_type', 'notifiable_id', 'channel', 'created_at'], 'notif_recip_chan_created_idx');
        });
    }
    public function down(): void { Schema::dropIfExists('notifications'); }
};