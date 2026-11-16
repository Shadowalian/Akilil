<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

class LiveStream extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = [
        'professional_user_id', 'category_id', 'recipe_id',
        'title', 'description', 'cover_image_path',
        'status', 'scheduled_at', 'started_at', 'ended_at', 'room_name',
        'allow_comments', 'allow_gifts',
        'peak_viewers', 'total_viewers', 'likes_count', 'gifts_total_cents',
    ];

    protected function casts(): array
    {
        return [
            'scheduled_at' => 'datetime',
            'started_at'   => 'datetime',
            'ended_at'     => 'datetime',
            'allow_comments' => 'boolean',
            'allow_gifts'    => 'boolean',
            'peak_viewers'   => 'integer',
            'total_viewers'  => 'integer',
            'likes_count'    => 'integer',
            'gifts_total_cents' => 'integer',
        ];
    }

    public function professional(): BelongsTo
    {
        return $this->belongsTo(User::class, 'professional_user_id');
    }

    public function category(): BelongsTo
    {
        return $this->belongsTo(Category::class);
    }

    public function recipe(): BelongsTo
    {
        return $this->belongsTo(Recipe::class);
    }

    public function viewers(): HasMany
    {
        return $this->hasMany(LiveStreamViewer::class);
    }

    public function events(): HasMany
    {
        return $this->hasMany(LiveStreamEvent::class);
    }

    public function isLive(): bool
    {
        return $this->status === 'live';
    }

    /** Viewers who polled the feed recently enough to count as watching. */
    public function currentViewerCount(): int
    {
        return $this->viewers()
            ->where('is_banned', false)
            ->where('last_seen_at', '>=', now()->subSeconds((int) config('akilil.live.presence_window_seconds', 25)))
            ->count();
    }
}
