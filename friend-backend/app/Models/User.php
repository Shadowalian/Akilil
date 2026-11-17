<?php

namespace App\Models;

use Filament\Models\Contracts\FilamentUser;
use Filament\Panel;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Database\Eloquent\Relations\MorphMany;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;
use Spatie\Permission\Traits\HasRoles;

/**
 * Akilil Platform — single users table.
 *
 *   role: user | professional
 *     (mirrors a row in professional_profiles for the 'professional' case;
 *      used for fast UI-routing queries without joining)
 *
 *   spatie roles: admin | support | moderator
 *     (admin-side RBAC; completely independent of users.role)
 *
 *   2FA fields are TOTP (RFC 6238). Recovery codes are encrypted at rest
 *   in Task 10 (column-level). totp_secret is encrypted in Task 10.
 *
 *   Soft deletes are ON per spec.
 */
class User extends Authenticatable implements FilamentUser
{
    /** @use HasFactory<\Database\Factories\UserFactory> */
    use HasFactory, Notifiable, SoftDeletes;
    use HasApiTokens, HasRoles;

    protected $fillable = [
        'name', 'email', 'password',
        'role', 'locale', 'timezone',
        'avatar_path', 'gender', 'date_of_birth',
        'guardian_user_id', 'seeking_care_for', 'phone', 'terms_accepted_at',
    ];

    protected $hidden = [
        'password', 'remember_token',
        'totp_secret', 'totp_recovery_codes',
    ];

    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password'          => 'hashed',
            'totp_enabled'      => 'boolean',
            'totp_recovery_codes' => 'encrypted:array',     // Task 10 column-level
            'totp_secret'       => 'encrypted',
            'date_of_birth'     => 'date',
            'last_seen_at'      => 'datetime',
            'totp_confirmed_at' => 'datetime',
            'terms_accepted_at' => 'datetime',
        ];
    }

    /* ---- Spatie admin gate ---- */
    public function canAccessPanel(Panel $panel): bool
    {
        return $this->hasAnyRole(['admin', 'support', 'moderator']);
    }

    /* ---- Persona helpers ---- */
    public function isProfessional(): bool { return $this->role === 'professional'; }
    public function isEndUser(): bool      { return $this->role === 'user'; }

    /* ---- Age ---- */

    /** Null when we were never told a date of birth. */
    public function age(): ?int
    {
        return $this->date_of_birth ? (int) $this->date_of_birth->diffInYears(now()) : null;
    }

    /**
     * Minors are guardian-managed teen logins, or anyone whose stated
     * date of birth puts them under the adult age.
     */
    public function isMinor(): bool
    {
        if ($this->guardian_user_id) {
            return true;
        }
        $age = $this->age();

        return $age !== null && $age < (int) config('akilil.adult_age', 18);
    }

    /** children | teens | adults */
    public static function ageGroupFor(int $age): string
    {
        foreach (config('akilil.age_groups') as $group => [$min, $max]) {
            if ($age >= $min && $age <= $max) {
                return $group;
            }
        }

        return 'adults';
    }

    /* ---- Relationships ---- */

    public function guardian(): \Illuminate\Database\Eloquent\Relations\BelongsTo
    {
        return $this->belongsTo(self::class, 'guardian_user_id');
    }

    public function dependents(): HasMany
    {
        return $this->hasMany(Dependent::class, 'guardian_user_id');
    }

    /** The dependent record behind a teen login. */
    public function dependentProfile(): HasOne
    {
        return $this->hasOne(Dependent::class, 'linked_user_id');
    }

    public function safetyPlan(): HasOne
    {
        return $this->hasOne(SafetyPlan::class);
    }

    public function recipes(): HasMany
    {
        return $this->hasMany(Recipe::class, 'professional_user_id');
    }

    public function earnings(): HasMany
    {
        return $this->hasMany(Earning::class, 'professional_user_id');
    }

    public function professionalProfile(): HasOne
    {
        return $this->hasOne(ProfessionalProfile::class);
    }

    public function professionalDocuments(): HasMany
    {
        return $this->hasMany(ProfessionalDocument::class);
    }

    public function availabilitySlotRules(): HasMany
    {
        return $this->hasMany(AvailabilitySlotRule::class);
    }

    public function availabilityBlocks(): HasMany
    {
        return $this->hasMany(AvailabilityBlock::class);
    }

    public function appointmentsAsClient(): HasMany
    {
        return $this->hasMany(Appointment::class, 'user_id');
    }

    public function appointmentsAsProfessional(): HasMany
    {
        return $this->hasMany(Appointment::class, 'professional_user_id');
    }

    public function journalEntries(): HasMany
    {
        return $this->hasMany(JournalEntry::class);
    }

    public function moodLogs(): HasMany
    {
        return $this->hasMany(MoodLog::class);
    }

    public function wallets(): HasMany
    {
        return $this->hasMany(Wallet::class);
    }

    public function goals(): HasMany
    {
        return $this->hasMany(Goal::class);
    }

    public function habits(): HasMany
    {
        return $this->hasMany(Habit::class);
    }

    public function habitLogs(): HasMany
    {
        return $this->hasMany(HabitLog::class);
    }

    public function vents(): HasMany
    {
        return $this->hasMany(Vent::class, 'author_user_id');
    }

    public function communityPosts(): HasMany
    {
        return $this->hasMany(CommunityPost::class, 'author_id');
    }

    public function communityChannelMemberships(): HasMany
    {
        return $this->hasMany(CommunityChannelMember::class);
    }

    public function communityChannels(): BelongsToMany
    {
        return $this->belongsToMany(CommunityChannel::class, 'community_channel_members')
                    ->withPivot(['role', 'is_muted', 'last_read_at'])
                    ->withTimestamps();
    }

    public function conversationParticipations(): HasMany
    {
        return $this->hasMany(ConversationParticipant::class);
    }

    public function messages(): HasMany
    {
        return $this->hasMany(Message::class, 'sender_id');
    }

    public function wallet(): HasOne
    {
        return $this->hasOne(Wallet::class);
    }

    public function transactions(): HasMany
    {
        return $this->hasMany(Transaction::class);
    }

    public function subscriptions(): HasMany
    {
        return $this->hasMany(Subscription::class);
    }

    public function payouts(): HasMany
    {
        return $this->hasMany(Payout::class, 'professional_user_id');
    }

    public function devices(): HasMany
    {
        return $this->hasMany(Device::class);
    }

    public function notifications(): MorphMany
    {
        return $this->morphMany(UserNotification::class, 'notifiable')
                    ->orderBy('created_at', 'desc');
    }

    public function crisisFlags(): HasMany
    {
        return $this->hasMany(CrisisFlag::class);
    }
}