<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\MorphMany;
use Illuminate\Database\Eloquent\SoftDeletes;

class CommunityComment extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = [
        'post_id', 'author_id', 'content', 'parent_comment_id', 'moderation_status',
    ];

    public function post(): BelongsTo         { return $this->belongsTo(CommunityPost::class, 'post_id'); }
    public function author(): BelongsTo      { return $this->belongsTo(User::class, 'author_id'); }
    public function parent(): BelongsTo      { return $this->belongsTo(self::class, 'parent_comment_id'); }
    public function replies(): HasMany       { return $this->hasMany(self::class, 'parent_comment_id'); }
    public function reports(): MorphMany     { return $this->morphMany(CommunityReport::class, 'subject'); }
}