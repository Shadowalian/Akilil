<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ProfessionalDocument extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id', 'document_type', 'file_path', 'original_filename',
        'size_bytes', 'mime_type', 'description',
        'review_status', 'reviewed_by', 'reviewed_at', 'review_notes',
    ];

    protected function casts(): array
    {
        return ['reviewed_at' => 'datetime'];
    }

    public function user(): BelongsTo        { return $this->belongsTo(User::class); }
    public function reviewer(): BelongsTo    { return $this->belongsTo(User::class, 'reviewed_by'); }
}