<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class MoodLog extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id', 'mood_score', 'mood_tags', 'source', 'note', 'logged_at',
    ];

    protected function casts(): array
    {
        return [
            'mood_tags' => 'array',
            'logged_at' => 'datetime',
        ];
    }

    public function user(): BelongsTo { return $this->belongsTo(User::class); }
}