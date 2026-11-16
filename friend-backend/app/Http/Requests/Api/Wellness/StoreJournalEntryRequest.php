<?php

namespace App\Http\Requests\Api\Wellness;

use Illuminate\Foundation\Http\FormRequest;

class StoreJournalEntryRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        return [
            'client_uuid'      => ['nullable', 'uuid'],
            'mood_score'       => ['nullable', 'integer', 'min:1', 'max:10'],
            'mood_tags'        => ['nullable', 'array'],
            'mood_tags.*'      => ['string', 'max:32'],
            'content'          => ['required', 'string', 'max:50000'],
            'is_private'       => ['nullable', 'boolean'],
            'created_client_at'=> ['nullable', 'date'],
        ];
    }
}