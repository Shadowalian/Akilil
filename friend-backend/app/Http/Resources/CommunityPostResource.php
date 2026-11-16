<?php

namespace App\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

class CommunityPostResource extends JsonResource
{
    public function toArray($request): array
    {
        return [
            'id'                => $this->id,
            'channel_id'        => $this->channel_id,
            'content'           => $this->content,
            'media'             => $this->media,
            'client_uuid'       => $this->client_uuid,
            'reactions_count'   => (int) $this->reactions_count,
            'comments_count'    => (int) $this->comments_count,
            'moderation_status' => $this->moderation_status,
            'author'            => $this->whenLoaded('author', fn () => $this->author?->only(['id', 'name'])),
            'created_at'        => optional($this->created_at)?->toIso8601String(),
        ];
    }
}
