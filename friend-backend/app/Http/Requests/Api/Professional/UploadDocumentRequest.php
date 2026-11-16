<?php

namespace App\Http\Requests\Api\Professional;

use Illuminate\Foundation\Http\FormRequest;

class UploadDocumentRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        return [
            'document_type' => ['required', 'in:government_id,professional_license,degree,certification,background_check,other'],
            'file'          => ['required', 'file', 'max:10240', 'mimes:pdf,jpg,jpeg,png'],
            'description'   => ['nullable', 'string', 'max:512'],
        ];
    }
}
