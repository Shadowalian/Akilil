<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Subscription extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id', 'plan_id', 'status',
        'gateway', 'gateway_subscription_id',
        'trial_ends_at', 'current_period_starts_at', 'current_period_ends_at',
        'cancelled_at', 'cancel_at_period_end',
    ];

    protected function casts(): array
    {
        return [
            'cancel_at_period_end' => 'boolean',
            'trial_ends_at'        => 'datetime',
            'current_period_starts_at' => 'datetime',
            'current_period_ends_at'   => 'datetime',
            'cancelled_at'         => 'datetime',
        ];
    }

    public function user(): BelongsTo { return $this->belongsTo(User::class); }
    public function plan(): BelongsTo { return $this->belongsTo(SubscriptionPlan::class, 'plan_id'); }
}