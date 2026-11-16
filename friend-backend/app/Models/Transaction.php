<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\MorphTo;
use Illuminate\Database\Eloquent\SoftDeletes;

class Transaction extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = [
        'wallet_id', 'user_id', 'type', 'status',
        'amount_cents', 'currency', 'fee_cents_currency', 'fee_cents',
        'gateway', 'gateway_reference', 'gateway_payload',
        'reference_type', 'reference_id',
        'failure_reason', 'processed_at',
    ];

    protected function casts(): array
    {
        return [
            'amount_cents'   => 'integer',
            'fee_cents'      => 'integer',
            'gateway_payload'=> 'array',
            'processed_at'   => 'datetime',
        ];
    }

    public function wallet(): BelongsTo { return $this->belongsTo(Wallet::class); }
    public function user(): BelongsTo   { return $this->belongsTo(User::class); }
    public function reference(): MorphTo { return $this->morphTo(); }
}