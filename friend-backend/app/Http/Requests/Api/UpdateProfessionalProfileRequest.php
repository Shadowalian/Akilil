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
            // Which session formats and client age groups this professional takes.
            'care_formats'             => ['sometimes', 'array', 'min:1'],
            'care_formats.*'           => ['distinct', 'in:'.implode(',', config('akilil.care_formats'))],
            'age_groups'               => ['sometimes', 'array', 'min:1'],
            'age_groups.*'             => ['distinct', 'in:'.implode(',', array_keys(config('akilil.age_groups')))],
            'couples_rate_cents'       => ['sometimes', 'nullable', 'integer', 'min:0'],
            'family_rate_cents'        => ['sometimes', 'nullable', 'integer', 'min:0'],
            // Either a categories.id or a categories.slug — the controller resolves it.
            'category_id'              => ['sometimes', 'string'],
        ];
    }

    /** Offering child / teen sessions means serving that age group. */
    public function withValidator($validator): void
    {
        $validator->after(function ($v) {
            $profile = $this->user()?->professionalProfile;
            $formats = $this->input('care_formats', $profile?->offeredCareFormats() ?? ['individual']);
            $groups  = $this->input('age_groups', $profile?->servedAgeGroups() ?? ['adults']);
            if (! is_array($formats) || ! is_array($groups)) {
                return;
            }
            foreach (['child' => 'children', 'teen' => 'teens'] as $format => $group) {
                if (in_array($format, $formats, true) && ! in_array($group, $groups, true)) {
                    $v->errors()->add('age_groups', "Offering {$format} sessions requires serving {$group}.");
                }
            }
            if (array_intersect(['individual', 'couples'], $formats) && ! in_array('adults', $groups, true)) {
                $v->errors()->add('age_groups', 'Individual and couples sessions require serving adults.');
            }
        });
    }

    protected function prepareForValidation(): void
    {
        if ($this->has('category_id') && $this->input('category_id') !== null) {
            $this->merge(['category_id' => (string) $this->input('category_id')]);
        }
    }
}
