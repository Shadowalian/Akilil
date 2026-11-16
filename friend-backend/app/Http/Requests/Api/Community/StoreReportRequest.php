<?php

namespace App\Http\Requests\Api\Community;

use Illuminate\Foundation\Http\FormRequest;

class StoreReportRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        return [
            'reason' => ['required', 'in:spam,harassment,self_harm_concern,misinformation,inappropriate,other'],
            'description' => ['nullable', 'string', 'max:2000'],
        ];
    }
}
