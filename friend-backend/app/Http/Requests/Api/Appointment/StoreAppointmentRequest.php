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
            'session_type'         => ['nullable', 'in:video,voice,chat'],
            'user_timezone'        => ['nullable', 'string', 'max:64', 'timezone:all'],

            // Who the session is for and how it is delivered.
            'care_format'          => ['nullable', 'in:'.implode(',', config('akilil.care_formats'))],
            'dependent_id'         => ['nullable', 'integer'],
            // Partner (couples) or relatives (family) joining from their own device.
            'participants'         => ['nullable', 'array', 'max:5'],
            'participants.*.name'  => ['required', 'string', 'min:2', 'max:191'],
            'participants.*.email' => ['nullable', 'email:rfc', 'max:191'],
            // Required when booking a chef.
            'recipe_id'            => ['nullable', 'integer'],
            'client_note'          => ['nullable', 'string', 'max:1000'],
        ];
    }
}