<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\MorphMany;

class Message extends Model
{
    use HasFactory;

    protected $fillable = [
        'client_uuid', 'conversation_id', 'sender_id', 'parent_message_id',
        'message_type', 'content_encrypted', 'media_path',
        'media_size_bytes', 'media_duration_seconds',
        'is_edited', 'is_deleted', 'flagged_status',
    ];

    protected function casts(): array
    {
        return [
            'content_encrypted' => 'encrypted',   // Task 10 layer
            'is_edited'         => 'boolean',
            'is_deleted'        => 'boolean',
            'media_size_bytes'  => 'integer',
            'media_duration_seconds' => 'integer',
        ];
    }

    public function conversation(): BelongsTo
    {
        return $this->belongsTo(Conversation::class);
    }

    public function sender(): BelongsTo
    {
        return $this->belongsTo(User::class, 'sender_id');
    }

    public function parentMessage(): BelongsTo
    {
        return $this->belongsTo(self::class, 'parent_message_id');
    }

    public function reports(): MorphMany
    {
        return $this->morphMany(CommunityReport::class, 'subject');
    }
}