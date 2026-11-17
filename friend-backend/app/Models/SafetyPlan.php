<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * A person's crisis safety plan. Encrypted at rest; readable by the
 * person, the professionals they have booked, and safety staff.
 */
class SafetyPlan extends Model
{
    protected $fillable = ['user_id', 'plan'];

    protected function casts(): array
    {
        return ['plan' => 'encrypted:array'];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
