<?php

namespace App\Http\Requests\Api\Session;

use Illuminate\Foundation\Http\FormRequest;

class StoreSessionNoteRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        return [
            'notes'        => ['required', 'string', 'max:50000'],
            'action_items' => ['nullable', 'array'],
        ];
    }
}
