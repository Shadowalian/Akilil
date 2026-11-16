<?php

namespace App\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

class VentResource extends JsonResource
{
    public function toArray($request): array
    {
        return [
            'id'          => $this->id,
            'content_type'=> $this->content_type,
            'content'     => $this->content,
            'voice_url'   => $this->voice_path ? route('media.serve', ['path' => $this->voice_path], false) : null,
            'voice_duration_seconds' => $this->voice_duration_seconds,
            'is_anonymous'=> (bool) $this->is_anonymous,
            'expires_at'  => optional($this->expires_at)?->toIso8601String(),
            'flagged_status' => $this->flagged_status,
            'reactions_count' => $this->reactions_count,
            'comments_count'  => $this->comments_count,
            'created_at'  => optional($this->created_at)?->toIso8601String(),
        ];
    }
}