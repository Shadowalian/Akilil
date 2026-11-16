<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class IngredientChecklist extends Model
{
    protected $fillable = ['user_id', 'recipe_id', 'checked_ingredient_ids'];

    protected function casts(): array
    {
        return ['checked_ingredient_ids' => 'array'];
    }
}
