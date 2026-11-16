<?php

namespace App\Http\Requests\Api\Messaging;

use Illuminate\Foundation\Http\FormRequest;

class SendMessageRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        $type = $this->input('message_type', 'text');
        return [
            'message_type'   => ['nullable', 'in:text,voice,image'],
            'content'        => [$type === 'text' ? 'required' : 'nullable', 'string', 'max:8000'],
            'file'           => [$type !== 'text' ? 'required' : 'nullable', 'file', 'max:51200', 'mimes:jpg,jpeg,png,webp,mp3,m4a,ogg,wav,aac'],
            'duration_seconds' => ['nullable', 'integer', 'min:1', 'max:600'],
            'caption'        => ['nullable', 'string', 'max:500'],
            'parent_message_id' => ['nullable', 'integer', 'exists:messages,id'],
            'client_uuid'    => ['nullable', 'uuid'],
        ];
    }
}