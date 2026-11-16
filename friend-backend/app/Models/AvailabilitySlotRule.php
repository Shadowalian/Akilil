<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class AvailabilitySlotRule extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id', 'weekday', 'start_time', 'end_time',
        'slot_duration_minutes', 'buffer_minutes', 'timezone',
        'effective_from', 'effective_until', 'is_active',
    ];

    protected function casts(): array
    {
        return [
            'is_active' => 'boolean',
            'effective_from' => 'date',
            'effective_until' => 'date',
        ];
    }

    public function professional(): BelongsTo
    {
        return $this->belongsTo(User::class, 'user_id');
    }
}