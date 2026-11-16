<?php

namespace App\Http\Requests\Api;

use Illuminate\Foundation\Http\FormRequest;

class UpdateMeRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        return [
            'name'                  => ['sometimes', 'string', 'min:2', 'max:191'],
            'locale'                => ['sometimes', 'string', 'size:2'],
            'timezone'              => ['sometimes', 'string', 'max:64'],
            'avatar_path'           => ['sometimes', 'nullable', 'string', 'max:512'],
            'gender'                => ['sometimes', 'nullable', 'in:female,male,non_binary,prefer_not_to_say'],
            'date_of_birth'         => ['sometimes', 'nullable', 'date'],
        ];
    }
}
