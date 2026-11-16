<?php

namespace App\Http\Requests\Api\Auth;

use Illuminate\Foundation\Http\FormRequest;

class TwoFactorConfirmRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        return [
            'code'     => ['required', 'string', 'regex:/^\d{6}$/'],
            'password' => ['required', 'current_password'],
        ];
    }
}