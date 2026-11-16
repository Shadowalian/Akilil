<?php

namespace App\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

class MoodLogResource extends JsonResource
{
    public function toArray($request): array
    {
        return [
            'id'         => $this->id,
            'mood_score' => $this->mood_score,
            'mood_tags'  => $this->mood_tags,
            'source'     => $this->source,
            'note'       => $this->note,
            'logged_at'  => optional($this->logged_at)?->toIso8601String(),
            'created_at' => optional($this->created_at)?->toIso8601String(),
        ];
    }
}