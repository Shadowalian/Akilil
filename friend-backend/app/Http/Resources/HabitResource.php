<?php

namespace App\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

class HabitResource extends JsonResource
{
    public function toArray($request): array
    {
        return [
            'id'           => $this->id,
            'title'        => $this->title,
            'description'  => $this->description,
            'cadence'      => $this->cadence,
            'days_of_week' => $this->days_of_week,
            'icon'         => $this->icon,
            'color_token'  => $this->color_token,
            'is_archived'  => (bool) $this->is_archived,
            'recent_logs'  => $this->whenLoaded('logs', fn () =>
                $this->logs->map(fn ($l) => [
                    'log_date' => $l->log_date->toDateString(),
                    'completed'=> (bool) $l->completed,
                    'note'     => $l->note,
                ])
            ),
            'created_at'   => optional($this->created_at)?->toIso8601String(),
        ];
    }
}