<?php

namespace App\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

class ConversationResource extends JsonResource
{
    public function toArray($request): array
    {
        $user = $request->user();
        $me = $this->participants->firstWhere('user_id', $user->id);

        return [
            'id'            => $this->id,
            'type'          => $this->type,
            'title'         => $this->title,
            'created_by'    => $this->created_by,
            'last_message_at' => optional($this->last_message_at)?->toIso8601String(),
            'last_message'  => $this->whenLoaded('messages', fn () => $this->messages->first() ? [
                'id'         => $this->messages->first()->id,
                'message_type' => $this->messages->first()->message_type,
                'created_at'   => $this->messages->first()->created_at?->toIso8601String(),
                'preview'      => $this->messages->first()->message_type === 'text'
                    ? \Illuminate\Support\Str::limit($this->messages->first()->content_encrypted ?? '', 80)
                    : '[' . $this->messages->first()->message_type . ']',
            ] : null),
            'participants'  => $this->whenLoaded('participants', fn () =>
                $this->participants->map(fn ($p) => [
                    'id'       => $p->user_id,
                    'name'     => $p->user?->name,
                    'role'     => $p->role,
                    'is_muted' => (bool) $p->is_muted,
                    'last_read_at' => optional($p->last_read_at)?->toIso8601String(),
                ])
            ),
            'unread_count'  => $me ? max(0, (int) $this->last_message_id - (int) $me->last_read_message_id) : 0,
            'created_at'    => optional($this->created_at)?->toIso8601String(),
        ];
    }
}