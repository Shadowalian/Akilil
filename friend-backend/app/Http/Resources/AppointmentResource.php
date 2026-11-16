<?php

namespace App\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

class AppointmentResource extends JsonResource
{
    public function toArray($request): array
    {
        return [
            'id'                        => $this->id,
            'user_id'                   => $this->user_id,
            'professional_user_id'      => $this->professional_user_id,
            'professional_profile_id'   => $this->professional_profile_id,
            'scheduled_at'              => optional($this->scheduled_at)?->toIso8601String(),
            'duration_minutes'          => $this->duration_minutes,
            'session_type'              => $this->session_type,
            'kind'                      => $this->kind ?? 'scheduled',
            'status'                    => $this->status,
            'price_cents'               => $this->price_cents,
            'currency'                  => $this->currency,
            'user_timezone'             => $this->user_timezone,
            'professional_timezone'     => $this->professional_timezone,
            'client_note'               => $this->client_note,
            'confirmed_at'              => optional($this->confirmed_at)?->toIso8601String(),
            'started_at'                => optional($this->started_at)?->toIso8601String(),
            'ended_at'                  => optional($this->ended_at)?->toIso8601String(),
            'cancelled_at'              => optional($this->cancelled_at)?->toIso8601String(),
            'cancellation_reason'       => $this->cancellation_reason,
            'client'   => $this->whenLoaded('client',   fn () => $this->client?->only(['id','name','avatar_path'])),
            'professional' => $this->whenLoaded('professional', fn () => $this->professional?->only(['id','name','avatar_path'])),
            'call_session' => $this->whenLoaded('callSession'),
            'review' => $this->whenLoaded('review', fn () => $this->review ? [
                'id'     => $this->review->id,
                'rating' => $this->review->rating,
            ] : null),
            'created_at' => optional($this->created_at)?->toIso8601String(),
        ];
    }
}