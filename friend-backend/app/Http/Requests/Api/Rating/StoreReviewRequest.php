<?php

namespace App\Http\Requests\Api\Rating;

use Illuminate\Foundation\Http\FormRequest;

class StoreReviewRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        return [
            'rating'       => ['required', 'integer', 'min:1', 'max:5'],
            'comment'      => ['nullable', 'string', 'max:5000'],
            'is_anonymous' => ['nullable', 'boolean'],
        ];
    }
}
