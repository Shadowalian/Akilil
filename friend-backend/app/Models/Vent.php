<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;

class Vent extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = [
        'author_user_id', 'content_type', 'content', 'voice_path',
        'voice_duration_seconds', 'is_anonymous', 'expires_at',
        'flagged_status', 'reactions_count', 'comments_count',
    ];

    protected function casts(): array
    {
        return [
            'is_anonymous'           => 'boolean',
            'expires_at'             => 'datetime',
            'reactions_count'        => 'integer',
            'comments_count'         => 'integer',
            'voice_duration_seconds' => 'integer',
        ];
    }

    public function author(): BelongsTo
    {
        return $this->belongsTo(User::class, 'author_user_id');
    }
}