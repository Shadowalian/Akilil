<?php

namespace App\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

/**
 * Compact professional profile for the discovery list view.
 * Keeps the payload small even with 50 results per page.
 */
class ProfessionalListResource extends JsonResource
{
    public function toArray($request): array
    {
        return [
            'id'                => $this->id,
            'user_id'           => $this->user_id,
            'display_name'      => $this->whenLoaded('user', fn () => $this->user->name),
            'avatar_url'        => $this->whenLoaded('user', fn () => $this->user->avatar_path),
            'bio'               => $this->bio,
            'category'          => $this->whenLoaded('category', fn () => $this->category?->only(['id','slug','name'])),
            'experience_years'  => $this->experience_years,
            'hourly_rate_cents' => $this->hourly_rate_cents,
            'currency'          => $this->currency,
            'rating_avg'        => (float) $this->rating_avg,
            'rating_count'      => $this->rating_count,
            'badge_active'      => (bool) $this->badge_active,
            'verification_status' => $this->verification_status,
            'is_accepting_clients' => (bool) $this->is_accepting_clients,
            'offers_free_listening' => (bool) ($this->offers_free_listening ?? false),
            'intro_video_url'   => $this->intro_video_url,
        ];
    }
}