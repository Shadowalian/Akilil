<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class RecipeIngredient extends Model
{
    protected $fillable = [
        'recipe_id', 'name', 'quantity', 'unit', 'note', 'substitute',
        'is_optional', 'sort_order',
    ];

    protected function casts(): array
    {
        return ['is_optional' => 'boolean', 'sort_order' => 'integer'];
    }

    public function recipe(): BelongsTo
    {
        return $this->belongsTo(Recipe::class);
    }
}
