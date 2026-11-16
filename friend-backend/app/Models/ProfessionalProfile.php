<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

class ProfessionalProfile extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = [
        'user_id', 'category_id', 'experience_years', 'bio', 'intro_video_url',
        'verification_status', 'badge_active', 'badge_issued_at', 'badge_issued_by',
        'hourly_rate_cents', 'currency', 'session_duration_minutes', 'advance_booking_hours',
        'rating_avg', 'rating_count', 'sessions_completed', 'is_accepting_clients',
        'offers_free_listening',
        'care_formats', 'age_groups', 'couples_rate_cents', 'family_rate_cents',
    ];

    protected function casts(): array
    {
        return [
            'experience_years'    => 'integer',
            'hourly_rate_cents'   => 'integer',
            'session_duration_minutes' => 'integer',
            'advance_booking_hours' => 'integer',
            'rating_avg'          => 'decimal:2',
            'rating_count'        => 'integer',
            'sessions_completed'  => 'integer',
            'badge_active'        => 'boolean',
            'badge_issued_at'     => 'datetime',
            'is_accepting_clients'=> 'boolean',
            'offers_free_listening' => 'boolean',
            'care_formats'        => 'array',
            'age_groups'          => 'array',
            'couples_rate_cents'  => 'integer',
            'family_rate_cents'   => 'integer',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function category(): BelongsTo
    {
        return $this->belongsTo(Category::class);
    }

    public function specialties(): BelongsToMany
    {
        return $this->belongsToMany(Specialty::class, 'professional_specialty');
    }

    public function languages(): BelongsToMany
    {
        return $this->belongsToMany(Language::class, 'professional_language')
                    ->withPivot('proficiency');
    }

    public function documents(): HasMany
    {
        return $this->hasMany(ProfessionalDocument::class, 'user_id', 'user_id');
    }

    public function appointments(): HasMany
    {
        return $this->hasMany(Appointment::class, 'professional_profile_id');
    }

    public function ratingsReviews(): HasMany
    {
        return $this->hasMany(RatingReview::class, 'professional_user_id', 'user_id');
    }

    /** Formats this professional offers. Legacy rows offered individual sessions only. */
    public function offeredCareFormats(): array
    {
        return $this->care_formats ?: ['individual'];
    }

    /** Age groups this professional serves. Legacy rows served adults only. */
    public function servedAgeGroups(): array
    {
        return $this->age_groups ?: ['adults'];
    }

    public function offersFormat(string $format): bool
    {
        return in_array($format, $this->offeredCareFormats(), true);
    }

    public function servesAgeGroup(string $group): bool
    {
        return in_array($group, $this->servedAgeGroups(), true);
    }

    /** Session price for a format; couples/family fall back to the base rate. */
    public function priceFor(string $format): int
    {
        return (int) match ($format) {
            'couples' => $this->couples_rate_cents ?? $this->hourly_rate_cents,
            'family'  => $this->family_rate_cents ?? $this->hourly_rate_cents,
            default   => $this->hourly_rate_cents,
        };
    }

    public function isCookingPillar(): bool
    {
        return $this->category?->slug === config('akilil.cooking.pillar');
    }

    public function scopeVerified($q)        { return $q->where('verification_status', 'approved'); }
    public function scopeApproved($q)        { return $q->where('verification_status', 'approved'); }
    public function scopeAccepting($q)       { return $q->where('is_accepting_clients', true); }
    public function scopeTopRated($q)        { return $q->orderByDesc('rating_avg'); }
}