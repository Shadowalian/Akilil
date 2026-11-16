<?php

namespace App\Http\Requests\Api\Wellness;

use Illuminate\Foundation\Http\FormRequest;

class StoreMoodLogRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        return [
            'mood_score'  => ['required', 'integer', 'min:1', 'max:10'],
            'mood_tags'   => ['nullable', 'array'],
            'source'      => ['nullable', 'in:manual,checkin,widget,journal,app'],
            'note'        => ['nullable', 'string', 'max:500'],
            'logged_at'   => ['nullable', 'date'],
        ];
    }
}