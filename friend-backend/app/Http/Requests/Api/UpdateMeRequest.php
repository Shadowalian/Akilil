<?php

namespace App\Http\Requests\Api;

use Illuminate\Foundation\Http\FormRequest;

class UpdateMeRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function messages(): array
    {
        return [
            'date_of_birth.before_or_equal' => 'You must be 18 or older. A parent or guardian can add you to their account.',
        ];
    }

    public function rules(): array
    {
        return [
            'name'                  => ['sometimes', 'string', 'min:2', 'max:191'],
            'locale'                => ['sometimes', 'string', 'size:2'],
            'timezone'              => ['sometimes', 'string', 'max:64'],
            'avatar_path'           => ['sometimes', 'nullable', 'string', 'max:512'],
            'gender'                => ['sometimes', 'nullable', 'in:female,male,non_binary,prefer_not_to_say'],
            // Accounts are adult-only; minors are dependents of a guardian.
            'date_of_birth'         => ['sometimes', 'date', 'after:1900-01-01', 'before_or_equal:'.now()->subYears((int) config('akilil.adult_age'))->toDateString()],
            'seeking_care_for'      => ['sometimes', 'in:self,child,couple,family'],
            'phone'                 => ['sometimes', 'nullable', 'string', 'max:32'],
        ];
    }
}
