<?php

namespace App\Http\Requests\Api\Wellness;

use Illuminate\Foundation\Http\FormRequest;

class UpdateHabitRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        return [
            'title'        => ['sometimes', 'string', 'max:191'],
            'description'  => ['sometimes', 'string', 'max:2000'],
            'cadence'      => ['sometimes', 'in:daily,weekdays,weekly,custom'],
            'days_of_week' => ['sometimes', 'array'],
            'days_of_week.*'=> ['integer', 'between:1,7'],
            'icon'         => ['sometimes', 'string', 'max:64'],
            'color_token'  => ['sometimes', 'string', 'max:32'],
            'is_archived'  => ['sometimes', 'boolean'],
        ];
    }
}