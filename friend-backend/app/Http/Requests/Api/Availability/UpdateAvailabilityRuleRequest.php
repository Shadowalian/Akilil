<?php

namespace App\Http\Requests\Api\Availability;

use Illuminate\Foundation\Http\FormRequest;

class UpdateAvailabilityRuleRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        return [
            'weekday'                 => ['sometimes', 'integer', 'min:1', 'max:7'],
            'start_time'              => ['sometimes', 'date_format:H:i'],
            'end_time'                => ['sometimes', 'date_format:H:i', 'after:start_time'],
            'slot_duration_minutes'   => ['sometimes', 'integer', 'min:15', 'max:240'],
            'buffer_minutes'          => ['sometimes', 'integer', 'min:0', 'max:120'],
            'timezone'                => ['sometimes', 'string', 'max:64', 'timezone:all'],
            'effective_from'          => ['sometimes', 'nullable', 'date'],
            'effective_until'         => ['sometimes', 'nullable', 'date', 'after_or_equal:effective_from'],
        ];
    }
}