<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

/**
 * A minor in the care of a guardian account. The guardian consents,
 * books and pays; the dependent is who the session is for.
 */
class Dependent extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = [
        'guardian_user_id', 'linked_user_id', 'name', 'date_of_birth', 'gender',
        'relationship', 'care_notes',
        'consent_version', 'consent_accepted_at', 'consent_ip',
    ];

    protected $hidden = ['consent_ip'];

    protected function casts(): array
    {
        return [
            'date_of_birth'       => 'date',
            'consent_accepted_at' => 'datetime',
            'care_notes'          => 'encrypted',
        ];
    }

    public function guardian(): BelongsTo
    {
        return $this->belongsTo(User::class, 'guardian_user_id');
    }

    public function linkedUser(): BelongsTo
    {
        return $this->belongsTo(User::class, 'linked_user_id');
    }

    public function appointments(): HasMany
    {
        return $this->hasMany(Appointment::class);
    }

    public function age(): int
    {
        return (int) $this->date_of_birth->diffInYears(now());
    }

    /** children | teens | adults — see config('akilil.age_groups'). */
    public function ageGroup(): string
    {
        return User::ageGroupFor($this->age());
    }
}
