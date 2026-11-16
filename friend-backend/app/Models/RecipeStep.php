<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class RecipeStep extends Model
{
    protected $fillable = ['recipe_id', 'position', 'instruction', 'duration_minutes'];

    protected function casts(): array
    {
        return ['position' => 'integer', 'duration_minutes' => 'integer'];
    }

    public function recipe(): BelongsTo
    {
        return $this->belongsTo(Recipe::class);
    }
}
