<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

class TherapyGroup extends Model
{
    use SoftDeletes;

    protected $fillable = [
        'professional_user_id', 'title', 'description', 'max_members',
        'is_open', 'price_cents', 'currency', 'status',
    ];

    protected function casts(): array
    {
        return [
            'max_members' => 'integer',
            'is_open' => 'boolean',
            'price_cents' => 'integer',
        ];
    }

    public function professional(): BelongsTo
    {
        return $this->belongsTo(User::class, 'professional_user_id');
    }

    public function members(): HasMany
    {
        return $this->hasMany(TherapyGroupMember::class);
    }

    public function activeMembers(): HasMany
    {
        return $this->hasMany(TherapyGroupMember::class)->where('status', 'active');
    }

    public function meetings(): HasMany
    {
        return $this->hasMany(TherapyGroupMeeting::class);
    }

    public function scopeActive($q)
    {
        return $q->where('status', 'active');
    }

    public function scopeOpen($q)
    {
        return $q->where('is_open', true)->where('status', 'active');
    }
}
