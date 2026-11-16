<?php

namespace App\Http\Requests\Api\Auth;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rules\Password;

class RegisterRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function messages(): array
    {
        return [
            'date_of_birth.required' => 'Please tell us your date of birth.',
            'accept_terms.accepted'  => 'Please accept the terms and privacy policy to continue.',
        ];
    }

    public function rules(): array
    {
        return [
            'name'       => ['required', 'string', 'min:2', 'max:191'],
            'email'      => ['required', 'email:rfc', 'max:191', 'unique:users,email'],
            'password'   => ['required', 'confirmed', Password::min(8)->mixedCase()->numbers()],
            // Age gate: we ask everyone, and under-18s are sent to a guardian.
            'date_of_birth'    => ['required', 'date', 'before:today', 'after:1900-01-01'],
            // Who the person is here for — drives onboarding and matching.
            'seeking_care_for' => ['nullable', 'in:self,child,couple,family'],
            'gender'           => ['nullable', 'in:female,male,non_binary,prefer_not_to_say'],
            'phone'            => ['nullable', 'string', 'max:32'],
            'accept_terms'     => ['accepted'],
            'locale'     => ['nullable', 'string', 'size:2'],
            'timezone'   => ['nullable', 'string', 'max:64'],
            'device_name' => ['nullable', 'string', 'max:191'],
            'platform'   => ['nullable', 'in:ios,android,web'],
        ];
    }
}