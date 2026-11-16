<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\MorphMany;
use Illuminate\Database\Eloquent\SoftDeletes;

class CommunityPost extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = [
        'channel_id', 'author_id', 'client_uuid', 'content', 'media',
        'parent_post_id', 'reactions_count', 'comments_count', 'moderation_status',
    ];

    protected function casts(): array
    {
        return [
            'media'            => 'array',
            'reactions_count'  => 'integer',
            'comments_count'   => 'integer',
        ];
    }

    public function channel(): BelongsTo       { return $this->belongsTo(CommunityChannel::class, 'channel_id'); }
    public function author(): BelongsTo        { return $this->belongsTo(User::class, 'author_id'); }
    public function parentPost(): BelongsTo    { return $this->belongsTo(self::class, 'parent_post_id'); }
    public function replies(): HasMany         { return $this->hasMany(self::class, 'parent_post_id'); }
    public function comments(): HasMany       { return $this->hasMany(CommunityComment::class, 'post_id'); }
    public function reports(): MorphMany      { return $this->morphMany(CommunityReport::class, 'subject'); }
}