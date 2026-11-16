<?php

namespace App\Http\Requests\Api\Professional;

use Illuminate\Foundation\Http\FormRequest;

class StorePayoutRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        return [
            'amount_cents' => ['required', 'integer', 'min:1000'],
        ];
    }
}
