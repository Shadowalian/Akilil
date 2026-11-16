<?php

namespace App\Http\Requests\Api;

use Illuminate\Foundation\Http\FormRequest;

class UpdateProfessionalProfileRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        return [
            'bio'                      => ['sometimes', 'nullable', 'string', 'max:5000'],
            'experience_years'         => ['sometimes', 'integer', 'min:0', 'max:80'],
            'hourly_rate_cents'        => ['sometimes', 'integer', 'min:0'],
            'session_duration_minutes' => ['sometimes', 'integer', 'min:15', 'max:240'],
            'is_accepting_clients'     => ['sometimes', 'boolean'],
            'offers_free_listening'    => ['sometimes', 'boolean'],
            // Either a categories.id or a categories.slug — the controller resolves it.
            'category_id'              => ['sometimes', 'string'],
        ];
    }

    protected function prepareForValidation(): void
    {
        if ($this->has('category_id') && $this->input('category_id') !== null) {
            $this->merge(['category_id' => (string) $this->input('category_id')]);
        }
    }
}
