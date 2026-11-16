<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class CommunityChannelMember extends Model
{
    use HasFactory;

    protected $fillable = [
        'channel_id', 'user_id', 'role', 'is_muted', 'last_read_at',
    ];

    protected function casts(): array
    {
        return ['is_muted' => 'boolean', 'last_read_at' => 'datetime'];
    }

    public function channel(): BelongsTo { return $this->belongsTo(CommunityChannel::class, 'channel_id'); }
    public function user(): BelongsTo    { return $this->belongsTo(User::class); }
}