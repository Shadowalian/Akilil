<?php

namespace App\Http\Requests\Api\Wellness;

use Illuminate\Foundation\Http\FormRequest;

class UpdateJournalEntryRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        return [
            'mood_score' => ['sometimes', 'integer', 'min:1', 'max:10'],
            'mood_tags'  => ['sometimes', 'array'],
            'content'    => ['sometimes', 'string', 'max:50000'],
            'is_private' => ['sometimes', 'boolean'],
        ];
    }
}