<?php

namespace App\Http\Requests\Api\Auth;

use Illuminate\Foundation\Http\FormRequest;

class RegisterProfessionalRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        return [
            'name'                  => ['required', 'string', 'min:2', 'max:191'],
            'email'                 => ['required', 'email:rfc', 'max:191', 'unique:users,email'],
            'password'              => ['required', 'confirmed', 'min:8'],
            // Optional during QA — app signup only collects name/email/password.
            'category_id'           => ['nullable', 'integer', 'exists:categories,id'],
            'experience_years'      => ['nullable', 'integer', 'min:0', 'max:70'],
            'bio'                   => ['nullable', 'string', 'max:2000'],
            'locale'                => ['nullable', 'string', 'size:2'],
            'timezone'              => ['nullable', 'string', 'max:64'],
        ];
    }
}