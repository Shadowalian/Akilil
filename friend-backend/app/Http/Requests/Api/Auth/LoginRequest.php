<?php

namespace App\Http\Requests\Api\Auth;

use Illuminate\Foundation\Http\FormRequest;

class LoginRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        return [
            'email'        => ['required', 'email:rfc'],
            'password'     => ['required', 'string'],
            'device_name'  => ['nullable', 'string', 'max:191'],
            'platform'     => ['nullable', 'in:ios,android,web'],
            'remember'     => ['nullable', 'boolean'],
        ];
    }
}