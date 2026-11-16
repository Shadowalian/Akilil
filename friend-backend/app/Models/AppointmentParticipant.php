<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * An extra person in a couples / family session (the partner, a parent,
 * a sibling). They join from their own device once they accept the invite.
 */
class AppointmentParticipant extends Model
{
    protected $fillable = [
        'appointment_id', 'user_id', 'name', 'email', 'role',
        'invite_token', 'status', 'accepted_at',
    ];

    protected $hidden = ['invite_token'];

    protected function casts(): array
    {
        return ['accepted_at' => 'datetime'];
    }

    public function appointment(): BelongsTo
    {
        return $this->belongsTo(Appointment::class);
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
