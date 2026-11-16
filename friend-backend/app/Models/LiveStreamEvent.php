<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class LiveStreamEvent extends Model
{
    protected $fillable = ['live_stream_id', 'user_id', 'type', 'body', 'payload', 'removed_at'];

    protected function casts(): array
    {
        return ['payload' => 'array', 'removed_at' => 'datetime'];
    }

    public function stream(): BelongsTo
    {
        return $this->belongsTo(LiveStream::class, 'live_stream_id');
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
