<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Database\Eloquent\SoftDeletes;

class Appointment extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = [
        'user_id', 'professional_user_id', 'professional_profile_id',
        'scheduled_at', 'user_timezone', 'professional_timezone', 'duration_minutes',
        'session_type', 'kind', 'status',
        'price_cents', 'currency',
        'confirmed_at', 'started_at', 'ended_at',
        'cancelled_at', 'cancelled_by', 'cancellation_reason', 'client_note',
    ];

    protected function casts(): array
    {
        return [
            'scheduled_at' => 'datetime',
            'confirmed_at' => 'datetime',
            'started_at'   => 'datetime',
            'ended_at'     => 'datetime',
            'cancelled_at' => 'datetime',
            'price_cents'  => 'integer',
            'duration_minutes' => 'integer',
        ];
    }

    public function client(): BelongsTo
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    public function professional(): BelongsTo
    {
        return $this->belongsTo(User::class, 'professional_user_id');
    }

    public function professionalProfile(): BelongsTo
    {
        return $this->belongsTo(ProfessionalProfile::class);
    }

    public function callSession(): HasOne
    {
        return $this->hasOne(CallSession::class);
    }

    public function notes(): HasMany
    {
        return $this->hasMany(SessionNote::class);
    }

    public function review(): HasOne
    {
        return $this->hasOne(RatingReview::class);
    }

    public function scopeUpcoming($q)
    {
        return $q->whereIn('status', ['pending', 'confirmed'])
                 ->where('scheduled_at', '>=', now());
    }

    public function scopeCompleted($q)
    {
        return $q->where('status', 'completed');
    }
}