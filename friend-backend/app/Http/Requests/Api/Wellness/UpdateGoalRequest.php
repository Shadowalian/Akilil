<?php

namespace App\Http\Requests\Api\Wellness;

use Illuminate\Foundation\Http\FormRequest;

class UpdateGoalRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        return [
            'title'        => ['sometimes', 'string', 'max:191'],
            'description'  => ['sometimes', 'string', 'max:2000'],
            'target'       => ['sometimes', 'string', 'max:191'],
            'due_date'     => ['sometimes', 'date'],
            'progress'     => ['sometimes', 'integer', 'min:0', 'max:100'],
            'status'       => ['sometimes', 'in:active,paused,completed,archived'],
        ];
    }
}