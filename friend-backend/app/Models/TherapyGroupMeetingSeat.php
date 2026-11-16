<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class TherapyGroupMeetingSeat extends Model
{
    protected $fillable = [
        'therapy_group_meeting_id', 'user_id', 'status', 'price_cents', 'currency',
        'transaction_id', 'ingredients_confirmed_at', 'joined_at',
    ];

    protected function casts(): array
    {
        return [
            'price_cents' => 'integer',
            'ingredients_confirmed_at' => 'datetime',
            'joined_at' => 'datetime',
        ];
    }

    public function meeting(): BelongsTo
    {
        return $this->belongsTo(TherapyGroupMeeting::class, 'therapy_group_meeting_id');
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function transaction(): BelongsTo
    {
        return $this->belongsTo(Transaction::class);
    }
}
