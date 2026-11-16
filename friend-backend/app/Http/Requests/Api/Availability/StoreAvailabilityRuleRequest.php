<?php

namespace App\Http\Requests\Api\Availability;

use Illuminate\Foundation\Http\FormRequest;

class StoreAvailabilityRuleRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        return [
            'weekday'                 => ['required', 'integer', 'min:1', 'max:7'],
            'start_time'              => ['required', 'date_format:H:i'],
            'end_time'                => ['required', 'date_format:H:i', 'after:start_time'],
            'slot_duration_minutes'   => ['required', 'integer', 'min:15', 'max:240'],
            'buffer_minutes'          => ['nullable', 'integer', 'min:0', 'max:120'],
            'timezone'                => ['required', 'string', 'max:64', 'timezone:all'],
            'effective_from'          => ['nullable', 'date'],
            'effective_until'         => ['nullable', 'date', 'after_or_equal:effective_from'],
            'is_active'               => ['nullable', 'boolean'],
        ];
    }
}