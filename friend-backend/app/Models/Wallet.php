<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Wallet extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id', 'currency', 'balance_cents', 'pending_cents',
        'lifetime_topup_cents', 'lifetime_spent_cents', 'version',
    ];

    protected function casts(): array
    {
        return [
            'balance_cents' => 'integer',
            'pending_cents' => 'integer',
            'lifetime_topup_cents' => 'integer',
            'lifetime_spent_cents' => 'integer',
            'version' => 'integer',
        ];
    }

    public function user(): BelongsTo      { return $this->belongsTo(User::class); }
    public function transactions(): HasMany { return $this->hasMany(Transaction::class); }
}