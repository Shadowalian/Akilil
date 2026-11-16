<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

class Recipe extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = [
        'professional_user_id', 'title', 'description', 'cuisine', 'difficulty',
        'prep_minutes', 'cook_minutes', 'servings', 'cover_image_path',
        'dietary_tags', 'allergens', 'equipment', 'status', 'published_at',
    ];

    protected function casts(): array
    {
        return [
            'prep_minutes' => 'integer',
            'cook_minutes' => 'integer',
            'servings'     => 'integer',
            'dietary_tags' => 'array',
            'allergens'    => 'array',
            'equipment'    => 'array',
            'published_at' => 'datetime',
        ];
    }

    public function professional(): BelongsTo
    {
        return $this->belongsTo(User::class, 'professional_user_id');
    }

    public function ingredients(): HasMany
    {
        return $this->hasMany(RecipeIngredient::class)->orderBy('sort_order')->orderBy('id');
    }

    public function steps(): HasMany
    {
        return $this->hasMany(RecipeStep::class)->orderBy('position');
    }

    public function scopePublished($q)
    {
        return $q->where('status', 'published');
    }

    public function isPublished(): bool
    {
        return $this->status === 'published';
    }
}
