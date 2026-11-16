<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;

class Payout extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = [
        'professional_user_id', 'amount_cents', 'currency', 'platform_fee_cents',
        'status', 'gateway', 'gateway_payout_id',
        'scheduled_for', 'processed_at', 'failure_reason',
    ];

    protected function casts(): array
    {
        return [
            'amount_cents'        => 'integer',
            'platform_fee_cents'  => 'integer',
            'scheduled_for'       => 'date',
            'processed_at'        => 'datetime',
        ];
    }

    public function professional(): BelongsTo
    {
        return $this->belongsTo(User::class, 'professional_user_id');
    }
}