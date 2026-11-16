<?php

namespace App\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

class ProfessionalDetailResource extends JsonResource
{
    public function toArray($request): array
    {
        return [
            'id'                       => $this->id,
            'user_id'                  => $this->user_id,
            'display_name'             => $this->whenLoaded('user', fn () => $this->user->name),
            'avatar_url'               => $this->whenLoaded('user', fn () => $this->user->avatar_path),
            'category'                 => $this->whenLoaded('category', fn () => $this->category?->only(['id','slug','name'])),
            'experience_years'         => $this->experience_years,
            'bio'                      => $this->bio,
            'intro_video_url'          => $this->intro_video_url,
            'verification_status'      => $this->verification_status,
            'badge_active'             => (bool) $this->badge_active,
            'badge_issued_at'          => optional($this->badge_issued_at)?->toIso8601String(),
            'hourly_rate_cents'        => $this->hourly_rate_cents,
            'currency'                 => $this->currency,
            'session_duration_minutes' => $this->session_duration_minutes,
            'advance_booking_hours'    => $this->advance_booking_hours,
            'rating_avg'               => (float) $this->rating_avg,
            'rating_count'             => $this->rating_count,
            'sessions_completed'       => $this->sessions_completed,
            'is_accepting_clients'     => (bool) $this->is_accepting_clients,
            'offers_free_listening'    => (bool) ($this->offers_free_listening ?? false),
            'care_formats'      => $this->offeredCareFormats(),
            'age_groups'        => $this->servedAgeGroups(),
            'couples_rate_cents' => $this->priceFor('couples'),
            'family_rate_cents'  => $this->priceFor('family'),
            'specialties'              => $this->whenLoaded('specialties', fn () =>
                $this->specialties->map(fn ($s) => ['id'=>$s->id,'slug'=>$s->slug,'name'=>$s->name])
            ),
            'languages'                => $this->whenLoaded('languages', fn () =>
                $this->languages->map(fn ($l) => ['id'=>$l->id,'code'=>$l->code,'name'=>$l->name,'proficiency'=>$l->pivot->proficiency])
            ),
            // Chefs: what you would cook together (clients pick one when booking).
            'requires_recipe'          => $this->isCookingPillar(),
            'cooking_min_lead_hours'   => $this->isCookingPillar() ? (int) config('akilil.cooking.min_lead_hours') : null,
            'approved_documents'       => $this->whenLoaded('documents', fn () =>
                $this->documents->map(fn ($d) => ['id'=>$d->id,'document_type'=>$d->document_type])
            ),
        ];
    }
}