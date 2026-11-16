<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class SubscriptionPlan extends Model
{
    use HasFactory;

    protected $fillable = [
        'slug', 'name', 'description', 'currency', 'price_cents',
        'interval', 'trial_days', 'features', 'limits',
        'is_active', 'sort_order',
    ];

    protected function casts(): array
    {
        return [
            'price_cents' => 'integer',
            'trial_days'  => 'integer',
            'features'    => 'array',
            'limits'      => 'array',
            'is_active'   => 'boolean',
            'sort_order'  => 'integer',
        ];
    }

    public function subscriptions(): HasMany
    {
        return $this->hasMany(Subscription::class, 'plan_id');
    }
}