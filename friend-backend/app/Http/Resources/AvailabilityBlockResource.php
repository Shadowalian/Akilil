<?php

namespace App\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

class AvailabilityBlockResource extends JsonResource
{
    public function toArray($request): array
    {
        return [
            'id'        => $this->id,
            'start_at'  => optional($this->start_at)?->toIso8601String(),
            'end_at'    => optional($this->end_at)?->toIso8601String(),
            'reason'    => $this->reason,
        ];
    }
}