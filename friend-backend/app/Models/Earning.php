<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\MorphTo;

class Earning extends Model
{
    protected $fillable = [
        'professional_user_id', 'kind', 'source_type', 'source_id',
        'gross_cents', 'fee_cents', 'net_cents', 'currency', 'status',
    ];

    protected function casts(): array
    {
        return [
            'gross_cents' => 'integer',
            'fee_cents'   => 'integer',
            'net_cents'   => 'integer',
        ];
    }

    public function professional(): BelongsTo
    {
        return $this->belongsTo(User::class, 'professional_user_id');
    }

    public function source(): MorphTo
    {
        return $this->morphTo();
    }
}
