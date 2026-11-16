<?php

namespace App\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

class GoalResource extends JsonResource
{
    public function toArray($request): array
    {
        return [
            'id'         => $this->id,
            'title'      => $this->title,
            'description'=> $this->description,
            'target'     => $this->target,
            'progress'   => $this->progress,
            'due_date'   => optional($this->due_date)?->toDateString(),
            'status'     => $this->status,
            'created_at' => optional($this->created_at)?->toIso8601String(),
        ];
    }
}