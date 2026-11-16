<?php

namespace App\Http\Requests\Api\Wellness;

use Illuminate\Foundation\Http\FormRequest;

class StoreHabitRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        return [
            'title'        => ['required', 'string', 'max:191'],
            'description'  => ['nullable', 'string', 'max:2000'],
            'cadence'      => ['nullable', 'in:daily,weekdays,weekly,custom'],
            'days_of_week' => ['nullable', 'array'],
            'days_of_week.*'=> ['integer', 'between:1,7'],
            'icon'         => ['nullable', 'string', 'max:64'],
            'color_token'  => ['nullable', 'string', 'max:32'],
        ];
    }
}