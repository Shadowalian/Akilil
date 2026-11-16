<?php

namespace App\Http\Requests\Api\Availability;

use Illuminate\Foundation\Http\FormRequest;

class StoreAvailabilityBlockRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        return [
            'start_at' => ['required', 'date'],
            'end_at'   => ['required', 'date', 'after:start_at'],
            'reason'   => ['nullable', 'string', 'max:255'],
        ];
    }
}