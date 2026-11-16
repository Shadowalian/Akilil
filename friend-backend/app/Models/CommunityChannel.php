<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

class CommunityChannel extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = [
        'created_by', 'slug', 'name', 'description', 'channel_type',
        'is_private', 'is_archived', 'cover_image_path', 'member_count',
    ];

    protected function casts(): array
    {
        return ['is_private' => 'boolean', 'is_archived' => 'boolean'];
    }

    public function creator(): BelongsTo       { return $this->belongsTo(User::class, 'created_by'); }
    public function members(): HasMany        { return $this->hasMany(CommunityChannelMember::class, 'channel_id'); }
    public function memberUsers(): BelongsToMany
    {
        return $this->belongsToMany(User::class, 'community_channel_members')
                    ->withPivot(['role', 'is_muted', 'last_read_at']);
    }
    public function posts(): HasMany          { return $this->hasMany(CommunityPost::class, 'channel_id'); }

    /**
     * Idempotent join. member_count is denormalised, so it only moves when a
     * membership row is actually created.
     */
    public function joinMember(int $userId): CommunityChannelMember
    {
        $member = CommunityChannelMember::firstOrCreate(
            ['channel_id' => $this->id, 'user_id' => $userId],
            ['role' => 'member', 'last_read_at' => now()],
        );

        if ($member->wasRecentlyCreated) {
            $this->increment('member_count');
        }

        return $member;
    }
}