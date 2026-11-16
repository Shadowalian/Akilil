<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/** Answers to the matching questionnaire. Encrypted at rest. */
class IntakeResponse extends Model
{
    protected $fillable = ['user_id', 'dependent_id', 'pillar', 'care_format', 'answers'];

    protected function casts(): array
    {
        return ['answers' => 'encrypted:array'];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function dependent(): BelongsTo
    {
        return $this->belongsTo(Dependent::class);
    }
}
