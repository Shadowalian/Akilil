<?php

namespace App\Http\Requests\Api\Appointment;

use Illuminate\Foundation\Http\FormRequest;

class RescheduleAppointmentRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        return [
            'scheduled_at'  => ['required', 'date'],
            'user_timezone' => ['nullable', 'string', 'max:64', 'timezone:all'],
        ];
    }
}