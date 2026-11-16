<?php

namespace App\Http\Requests\Api\Wellness;

use Illuminate\Foundation\Http\FormRequest;

class StoreVentRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        $type = $this->input('content_type', 'text');
        return [
            'content_type'   => ['required', 'in:text,voice'],
            'content'        => [$type === 'text' ? 'required' : 'nullable', 'string', 'max:10000'],
            'file'           => [$type === 'voice' ? 'required' : 'nullable', 'file', 'max:20480', 'mimes:mp3,m4a,ogg,wav'],
            'duration_seconds' => ['nullable', 'integer', 'min:1', 'max:600'],
            'is_anonymous'   => ['nullable', 'boolean'],
            'expires_at'     => ['nullable', 'date', 'after:now'],
        ];
    }
}