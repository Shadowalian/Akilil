<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Habit extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id', 'title', 'description', 'cadence',
        'days_of_week', 'icon', 'color_token', 'is_archived',
    ];

    protected function casts(): array
    {
        return [
            'days_of_week' => 'array',
            'is_archived'  => 'boolean',
        ];
    }

    public function user(): BelongsTo       { return $this->belongsTo(User::class); }
    public function logs(): HasMany         { return $this->hasMany(HabitLog::class); }
}