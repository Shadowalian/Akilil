<?php

namespace App\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

class RatingReviewResource extends JsonResource
{
    public function toArray($request): array
    {
        $isAnonymous = (bool) $this->is_anonymous;

        return [
            'id'                    => $this->id,
            'appointment_id'        => $this->appointment_id,
            'professional_user_id'  => $this->professional_user_id,
            'rating'                => (int) $this->rating,
            'comment'               => $this->comment,
            'is_anonymous'          => $isAnonymous,
            'client' => $isAnonymous
                ? null
                : $this->whenLoaded('client', fn () => $this->client?->only(['id', 'name', 'avatar_path'])),
            'response_from_professional' => $this->response_from_professional,
            'response_at'           => optional($this->response_at)?->toIso8601String(),
            'status'                => $this->status,
            'created_at'            => optional($this->created_at)?->toIso8601String(),
        ];
    }
}
