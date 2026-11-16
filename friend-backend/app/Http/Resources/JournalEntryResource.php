<?php

namespace App\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

class JournalEntryResource extends JsonResource
{
    public function toArray($request): array
    {
        return [
            'id'                => $this->id,
            'client_uuid'       => $this->client_uuid,
            'mood_score'        => $this->mood_score,
            'mood_tags'         => $this->mood_tags,
            'content'           => $this->content,
            'is_private'        => (bool) $this->is_private,
            'created_client_at' => optional($this->created_client_at)?->toIso8601String(),
            'created_at'        => optional($this->created_at)?->toIso8601String(),
            'updated_at'        => optional($this->updated_at)?->toIso8601String(),
        ];
    }
}