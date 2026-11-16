<?php

namespace App\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

class TherapyGroupResource extends JsonResource
{
    public function toArray($request): array
    {
        return [
            'id' => $this->id,
            'professional_user_id' => $this->professional_user_id,
            'title' => $this->title,
            'description' => $this->description,
            'max_members' => $this->max_members,
            'is_open' => (bool) $this->is_open,
            'price_cents' => $this->price_cents,
            'currency' => $this->currency,
            'status' => $this->status,
            'member_count' => $this->when(
                isset($this->active_members_count) || $this->relationLoaded('activeMembers'),
                fn () => $this->active_members_count ?? $this->activeMembers->count()
            ),
            'is_member' => $this->when(isset($this->is_member), (bool) $this->is_member),
            'professional' => $this->whenLoaded('professional', fn () => $this->professional?->only(['id', 'name', 'avatar_path'])),
            'created_at' => optional($this->created_at)?->toIso8601String(),
        ];
    }
}
