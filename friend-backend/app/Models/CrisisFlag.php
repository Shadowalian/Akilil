<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\MorphTo;

/**
 * Crisis flag — produced by Task 5's content-analysis pipeline.
 * This is a HARM-REDUCTION signal, NOT a diagnostic. Admin review
 * is always the deciding step. See Task 5 docs.
 */
class CrisisFlag extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id', 'source_type', 'source_id',
        'severity', 'matched_signals', 'status',
        'handled_by', 'handled_at', 'handling_notes',
    ];

    protected function casts(): array
    {
        return [
            'severity'        => 'decimal:3',
            'matched_signals' => 'array',
            'handled_at'      => 'datetime',
        ];
    }

    public function user(): BelongsTo        { return $this->belongsTo(User::class); }
    public function handler(): BelongsTo     { return $this->belongsTo(User::class, 'handled_by'); }
    public function source(): MorphTo        { return $this->morphTo(); }
}