<?php

namespace App\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

class TherapyGroupMeetingResource extends JsonResource
{
    public function toArray($request): array
    {
        return [
            'id' => $this->id,
            'therapy_group_id' => $this->therapy_group_id,
            'title' => $this->title,
            'scheduled_at' => optional($this->scheduled_at)?->toIso8601String(),
            'duration_minutes' => $this->duration_minutes,
            'status' => $this->status,
            'price_cents' => $this->price_cents,
            'currency' => $this->currency,
            'recipe' => $this->whenLoaded('recipe', fn () => $this->recipe ? [
                'id' => $this->recipe->id,
                'title' => $this->recipe->title,
            ] : null),
            'requires_ingredients' => (bool) $this->recipe_id,
            'seats_taken' => $this->when(isset($this->reserved_seats_count), fn () => $this->reserved_seats_count),
            // The caller's own seat, when the controller attached it.
            'my_seat' => $this->when($this->relationLoaded('mySeat'), fn () => $this->mySeat ? [
                'status' => $this->mySeat->status,
                'ingredients_confirmed' => (bool) $this->mySeat->ingredients_confirmed_at,
            ] : null),
            'started_at' => optional($this->started_at)?->toIso8601String(),
            'ended_at' => optional($this->ended_at)?->toIso8601String(),
            'group' => $this->whenLoaded('group', fn () => [
                'id' => $this->group->id,
                'title' => $this->group->title,
            ]),
        ];
    }
}
