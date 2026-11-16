<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\MorphTo;

/**
 * Akilil in-app + push notification record.
 *
 * Distinct from Laravel's Illuminate\Notifications\Notification (the
 * abstract class used by Notifiable to dispatch). This row is the durable
 * log of a single delivery, written by the notification channels
 * (database, broadcast, push) wired in Task 4.
 *
 * `id` is a UUID per Laravel notification convention so that consumers
 * can de-duplicate client-side (mobile notification center, etc).
 */
class UserNotification extends Model
{
    protected $table = 'notifications';
    public $incrementing = false;
    protected $keyType = 'string';

    protected $fillable = [
        'id', 'type', 'notifiable_type', 'notifiable_id',
        'data', 'read_at', 'channel', 'push_status',
        'pushed_at', 'failure_reason',
    ];

    protected function casts(): array
    {
        return [
            'data'      => 'array',
            'read_at'   => 'datetime',
            'pushed_at' => 'datetime',
        ];
    }

    public function notifiable(): MorphTo
    {
        return $this->morphTo();
    }
}