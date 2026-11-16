<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class TherapyGroupMeeting extends Model
{
    protected $fillable = [
        'therapy_group_id', 'title', 'scheduled_at', 'duration_minutes',
        'status', 'room_name', 'started_at', 'ended_at',
    ];

    protected function casts(): array
    {
        return [
            'scheduled_at' => 'datetime',
            'started_at' => 'datetime',
            'ended_at' => 'datetime',
            'duration_minutes' => 'integer',
        ];
    }

    public function group(): BelongsTo
    {
        return $this->belongsTo(TherapyGroup::class, 'therapy_group_id');
    }
}
