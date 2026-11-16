<?php

namespace App\Http\Requests\Api\Wellness;

use Illuminate\Foundation\Http\FormRequest;

class StoreGoalRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        return [
            'title'        => ['required', 'string', 'max:191'],
            'description'  => ['nullable', 'string', 'max:2000'],
            'target'       => ['nullable', 'string', 'max:191'],
            'due_date'     => ['nullable', 'date'],
            'progress'     => ['nullable', 'integer', 'min:0', 'max:100'],
            'status'       => ['nullable', 'in:active,paused,completed,archived'],
        ];
    }
}