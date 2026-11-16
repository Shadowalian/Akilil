<?php

namespace App\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

class AvailabilityRuleResource extends JsonResource
{
    public function toArray($request): array
    {
        return [
            'id'                     => $this->id,
            'weekday'                => $this->weekday,
            'start_time'             => substr((string) $this->start_time, 0, 5),
            'end_time'               => substr((string) $this->end_time, 0, 5),
            'slot_duration_minutes'  => $this->slot_duration_minutes,
            'buffer_minutes'         => $this->buffer_minutes,
            'timezone'               => $this->timezone,
            'effective_from'         => optional($this->effective_from)?->toDateString(),
            'effective_until'        => optional($this->effective_until)?->toDateString(),
            'is_active'              => (bool) $this->is_active,
        ];
    }
}