<?php

namespace App\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

class SessionNoteResource extends JsonResource
{
    public function toArray($request): array
    {
        return [
            'id'                   => $this->id,
            'appointment_id'       => $this->appointment_id,
            'professional_user_id' => $this->professional_user_id,
            'client_user_id'       => $this->client_user_id,
            'notes'                => $this->notes,
            'action_items'         => $this->action_items,
            'tags'                 => $this->tags,
            'created_at'           => optional($this->created_at)?->toIso8601String(),
        ];
    }
}
