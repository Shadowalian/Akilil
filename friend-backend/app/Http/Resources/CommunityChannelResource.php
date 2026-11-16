<?php

namespace App\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

class CommunityChannelResource extends JsonResource
{
    public function toArray($request): array
    {
        return [
            'id'           => $this->id,
            'slug'         => $this->slug,
            'name'         => $this->name,
            'description'  => $this->description,
            'member_count' => (int) $this->member_count,
            'channel_type' => $this->channel_type,
        ];
    }
}
