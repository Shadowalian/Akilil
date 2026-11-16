<?php

namespace App\Http\Requests\Api\Availability;

use Illuminate\Foundation\Http\FormRequest;

class AvailableSlotsRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        return [
            'date'             => ['required', 'date'],
            'timezone'         => ['nullable', 'string', 'max:64', 'timezone:all'],
            'duration_minutes' => ['nullable', 'integer', 'min:15', 'max:240'],
        ];
    }
}