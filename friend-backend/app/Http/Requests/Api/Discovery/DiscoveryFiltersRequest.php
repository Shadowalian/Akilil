<?php

namespace App\Http\Requests\Api\Discovery;

use Illuminate\Foundation\Http\FormRequest;

class DiscoveryFiltersRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        return [
            'category_id'        => ['nullable', 'integer', 'exists:categories,id'],
            'category'           => ['nullable', 'string', 'max:64'],
            'language_id'        => ['nullable', 'integer', 'exists:languages,id'],
            'language'           => ['nullable', 'string', 'size:2'],
            'specialty_id'       => ['nullable', 'integer', 'exists:specialties,id'],
            'gender'             => ['nullable', 'in:female,male,non_binary,prefer_not_to_say'],
            'min_rating'         => ['nullable', 'numeric', 'min:0', 'max:5'],
            'max_price_cents'    => ['nullable', 'integer', 'min:0'],
            'available_from'     => ['nullable', 'date'],
            'available_to'       => ['nullable', 'date', 'after_or_equal:available_from'],
            'care_format'        => ['nullable', 'in:'.implode(',', config('akilil.care_formats'))],
            'age_group'          => ['nullable', 'in:'.implode(',', array_keys(config('akilil.age_groups')))],
            // Shortcut: filter to people who work with this child's age group.
            'dependent_id'       => ['nullable', 'integer'],
            'sort'               => ['nullable', 'in:rating,price,newest,experience,match'],
            'page'               => ['nullable', 'integer', 'min:1'],
            'per_page'           => ['nullable', 'integer', 'min:1', 'max:50'],
        ];
    }
}