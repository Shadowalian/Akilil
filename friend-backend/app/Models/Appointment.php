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
        'user_id', 'dependent_id', 'professional_user_id', 'professional_profile_id',
        'recipe_id', 'care_format', 'refunded_cents', 'ingredients_confirmed_at',
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
            'refunded_cents' => 'integer',
            'ingredients_confirmed_at' => 'datetime',
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

    public function dependent(): BelongsTo
    {
        return $this->belongsTo(Dependent::class)->withTrashed();
    }

    public function recipe(): BelongsTo
    {
        return $this->belongsTo(Recipe::class)->withTrashed();
    }

    public function participants(): HasMany
    {
        return $this->hasMany(AppointmentParticipant::class);
    }

    /**
     * Everyone allowed in the room: the account holder, the professional,
     * accepted couples/family participants, and a teen with their own login.
     */
    public function canBeJoinedBy(User $user): bool
    {
        if ($user->id === $this->user_id || $user->id === $this->professional_user_id) {
            return true;
        }
        if ($this->dependent_id && $this->dependent?->linked_user_id === $user->id) {
            return true;
        }

        return $this->participants()
            ->where('user_id', $user->id)
            ->where('status', 'accepted')
            ->exists();
    }

    /** Appointments this user may see: booked, hosting, invited to, or their own as a teen. */
    public function scopeVisibleTo($q, User $user)
    {
        return $q->where(function ($qq) use ($user) {
            $qq->where('user_id', $user->id)
               ->orWhere('professional_user_id', $user->id)
               ->orWhereHas('participants', fn ($p) => $p->where('user_id', $user->id)->where('status', 'accepted'))
               ->orWhereHas('dependent', fn ($d) => $d->where('linked_user_id', $user->id));
        });
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