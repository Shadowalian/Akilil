<?php

namespace App\Http\Requests\Api\Auth;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rules\Password;

class RegisterRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        return [
            'name'       => ['required', 'string', 'min:2', 'max:191'],
            'email'      => ['required', 'email:rfc', 'max:191', 'unique:users,email'],
            'password'   => ['required', 'confirmed', Password::min(8)->mixedCase()->numbers()],
            'locale'     => ['nullable', 'string', 'size:2'],
            'timezone'   => ['nullable', 'string', 'max:64'],
            'device_name' => ['nullable', 'string', 'max:191'],
            'platform'   => ['nullable', 'in:ios,android,web'],
        ];
    }
}