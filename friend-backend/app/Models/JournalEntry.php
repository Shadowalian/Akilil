<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class JournalEntry extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id', 'client_uuid', 'mood_score', 'mood_tags',
        'content', 'is_private', 'created_client_at',
    ];

    protected function casts(): array
    {
        return [
            'mood_tags'        => 'array',
            // Private writing: encrypted at rest, as the app promises.
            'content'          => 'encrypted',
            'is_private'       => 'boolean',
            'created_client_at'=> 'datetime',
        ];
    }

    public function user(): BelongsTo { return $this->belongsTo(User::class); }
}