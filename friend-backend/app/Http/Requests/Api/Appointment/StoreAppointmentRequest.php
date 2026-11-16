<?php

namespace App\Http\Requests\Api\Appointment;

use Illuminate\Foundation\Http\FormRequest;

class StoreAppointmentRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        return [
            'professional_user_id' => ['required', 'integer', 'exists:users,id'],
            'scheduled_at'         => ['required', 'date'],
            'duration_minutes'     => ['nullable', 'integer', 'min:15', 'max:240'],
            'session_type'         => ['nullable', 'in:video,voice'],
            'user_timezone'        => ['nullable', 'string', 'max:64', 'timezone:all'],
        ];
    }
}