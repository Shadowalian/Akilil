<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class TherapyGroupMeeting extends Model
{
    protected $fillable = [
        'therapy_group_id', 'title', 'scheduled_at', 'duration_minutes',
        'status', 'room_name', 'started_at', 'ended_at',
        'price_cents', 'currency', 'recipe_id',
    ];

    protected function casts(): array
    {
        return [
            'scheduled_at' => 'datetime',
            'started_at' => 'datetime',
            'ended_at' => 'datetime',
            'duration_minutes' => 'integer',
            'price_cents' => 'integer',
        ];
    }

    public function recipe(): BelongsTo
    {
        return $this->belongsTo(Recipe::class)->withTrashed();
    }

    public function seats(): \Illuminate\Database\Eloquent\Relations\HasMany
    {
        return $this->hasMany(TherapyGroupMeetingSeat::class);
    }

    public function reservedSeats(): \Illuminate\Database\Eloquent\Relations\HasMany
    {
        return $this->seats()->where('status', 'reserved');
    }

    public function group(): BelongsTo
    {
        return $this->belongsTo(TherapyGroup::class, 'therapy_group_id');
    }
}
