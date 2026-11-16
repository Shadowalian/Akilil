<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;

class CallSession extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = [
        'appointment_id', 'started_at', 'ended_at', 'duration_seconds',
        'provider', 'room_name', 'room_token',
        'recording_url', 'recording_size_bytes', 'recording_duration_seconds', 'recording_status',
        'status',
    ];

    protected function casts(): array
    {
        return [
            'started_at' => 'datetime',
            'ended_at'   => 'datetime',
            'duration_seconds' => 'integer',
            'recording_size_bytes' => 'integer',
            'recording_duration_seconds' => 'integer',
        ];
    }

    public function appointment(): BelongsTo
    {
        return $this->belongsTo(Appointment::class);
    }
}