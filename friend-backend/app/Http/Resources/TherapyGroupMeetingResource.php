<?php

namespace App\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

class TherapyGroupMeetingResource extends JsonResource
{
    public function toArray($request): array
    {
        return [
            'id' => $this->id,
            'therapy_group_id' => $this->therapy_group_id,
            'title' => $this->title,
            'scheduled_at' => optional($this->scheduled_at)?->toIso8601String(),
            'duration_minutes' => $this->duration_minutes,
            'status' => $this->status,
            'room_name' => $this->room_name,
            'started_at' => optional($this->started_at)?->toIso8601String(),
            'ended_at' => optional($this->ended_at)?->toIso8601String(),
            'group' => $this->whenLoaded('group', fn () => [
                'id' => $this->group->id,
                'title' => $this->group->title,
            ]),
        ];
    }
}
