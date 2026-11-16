<?php

namespace App\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

class MessageResource extends JsonResource
{
    public function toArray($request): array
    {
        return [
            'id'                       => $this->id,
            'conversation_id'          => $this->conversation_id,
            'sender'                   => $this->whenLoaded('sender', fn () => $this->sender ? ['id'=>$this->sender->id,'name'=>$this->sender->name,'avatar_path'=>$this->sender->avatar_path] : null),
            'parent_message_id'        => $this->parent_message_id,
            'message_type'             => $this->message_type,
            'content_encrypted'        => $this->content_encrypted,
            'media_url'                => $this->media_path ? route('media.serve', ['path' => $this->media_path], false) : null,
            'media_size_bytes'         => $this->media_size_bytes,
            'media_duration_seconds'   => $this->media_duration_seconds,
            'is_edited'                => (bool) $this->is_edited,
            'is_deleted'               => (bool) $this->is_deleted,
            'flagged_status'           => $this->flagged_status,
            'client_uuid'              => $this->client_uuid,
            'created_at'               => optional($this->created_at)?->toIso8601String(),
        ];
    }
}