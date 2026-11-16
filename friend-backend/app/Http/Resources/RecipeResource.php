<?php

namespace App\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

class RecipeResource extends JsonResource
{
    public function toArray($request): array
    {
        return [
            'id'            => $this->id,
            'professional_user_id' => $this->professional_user_id,
            'chef'          => $this->whenLoaded('professional', fn () => $this->professional?->only(['id', 'name', 'avatar_path'])),
            'title'         => $this->title,
            'description'   => $this->description,
            'cuisine'       => $this->cuisine,
            'difficulty'    => $this->difficulty,
            'prep_minutes'  => $this->prep_minutes,
            'cook_minutes'  => $this->cook_minutes,
            'total_minutes' => $this->prep_minutes + $this->cook_minutes,
            'servings'      => $this->servings,
            'cover_image_url' => $this->cover_image_path,
            'dietary_tags'  => $this->dietary_tags ?? [],
            'allergens'     => $this->allergens ?? [],
            'equipment'     => $this->equipment ?? [],
            'status'        => $this->status,
            'published_at'  => $this->published_at?->toIso8601String(),
            'ingredient_count' => $this->when(
                isset($this->ingredients_count) || $this->relationLoaded('ingredients'),
                fn () => $this->ingredients_count ?? $this->ingredients->count()
            ),
            'ingredients'   => $this->whenLoaded('ingredients', fn () => $this->ingredients->map(fn ($i) => [
                'id'          => $i->id,
                'name'        => $i->name,
                'quantity'    => $i->quantity,
                'unit'        => $i->unit,
                'note'        => $i->note,
                'substitute'  => $i->substitute,
                'is_optional' => (bool) $i->is_optional,
            ])->values()),
            'steps'         => $this->whenLoaded('steps', fn () => $this->steps->map(fn ($s) => [
                'id'          => $s->id,
                'position'    => $s->position,
                'instruction' => $s->instruction,
                'duration_minutes' => $s->duration_minutes,
            ])->values()),
        ];
    }
}
