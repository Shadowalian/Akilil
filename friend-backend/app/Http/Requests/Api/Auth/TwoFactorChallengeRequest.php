<?php

namespace App\Http\Requests\Api\Auth;

use Illuminate\Foundation\Http\FormRequest;

class TwoFactorChallengeRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        return [
            'challenge_token' => ['required', 'string'],
            'code'            => ['required', 'string'],
            'recovery_code'   => ['nullable', 'string'],
        ];
    }
}