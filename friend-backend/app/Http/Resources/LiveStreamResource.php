<?php

namespace App\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

class LiveStreamResource extends JsonResource
{
    public function toArray($request): array
    {
        return [
            'id'            => $this->id,
            'title'         => $this->title,
            'description'   => $this->description,
            'cover_image_url' => $this->cover_image_path,
            'status'        => $this->status,
            'scheduled_at'  => $this->scheduled_at?->toIso8601String(),
            'started_at'    => $this->started_at?->toIso8601String(),
            'ended_at'      => $this->ended_at?->toIso8601String(),
            'allow_comments' => (bool) $this->allow_comments,
            'allow_gifts'    => (bool) $this->allow_gifts,
            'viewer_count'  => $this->status === 'live' ? $this->currentViewerCount() : 0,
            'peak_viewers'  => $this->peak_viewers,
            'total_viewers' => $this->total_viewers,
            'likes_count'   => $this->likes_count,
            'category'      => $this->whenLoaded('category', fn () => $this->category?->only(['id', 'slug', 'name'])),
            'host'          => $this->whenLoaded('professional', fn () => [
                'id'         => $this->professional?->id,
                'name'       => $this->professional?->name,
                'avatar_url' => $this->professional?->avatar_path,
            ]),
            'recipe'        => $this->whenLoaded('recipe', fn () => $this->recipe ? [
                'id'    => $this->recipe->id,
                'title' => $this->recipe->title,
            ] : null),
            'requires_ingredients' => (bool) $this->recipe_id,
            // Money figures are the host's business only.
            'gifts_total_cents' => $this->when(
                $request->user()?->id === $this->professional_user_id,
                $this->gifts_total_cents
            ),
            'is_host' => $request->user()?->id === $this->professional_user_id,
        ];
    }
}
