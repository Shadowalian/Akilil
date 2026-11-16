<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class GiftTransaction extends Model
{
    protected $fillable = [
        'gift_id', 'live_stream_id', 'sender_user_id', 'recipient_user_id',
        'quantity', 'unit_price_cents', 'total_cents', 'currency', 'transaction_id',
    ];

    protected function casts(): array
    {
        return ['quantity' => 'integer', 'unit_price_cents' => 'integer', 'total_cents' => 'integer'];
    }

    public function gift(): BelongsTo
    {
        return $this->belongsTo(Gift::class);
    }

    public function sender(): BelongsTo
    {
        return $this->belongsTo(User::class, 'sender_user_id');
    }
}
