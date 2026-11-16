<?php

namespace App\Http\Requests\Api\Community;

use Illuminate\Foundation\Http\FormRequest;

class StorePostRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        return [
            'content'     => ['required', 'string', 'min:1', 'max:5000'],
            'client_uuid' => ['nullable', 'uuid'],
        ];
    }
}
