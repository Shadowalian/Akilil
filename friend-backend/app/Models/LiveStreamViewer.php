<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class LiveStreamViewer extends Model
{
    protected $fillable = ['live_stream_id', 'user_id', 'joined_at', 'last_seen_at', 'is_banned'];

    protected function casts(): array
    {
        return [
            'joined_at'    => 'datetime',
            'last_seen_at' => 'datetime',
            'is_banned'    => 'boolean',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
