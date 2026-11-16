<?php

namespace App\Http\Requests\Api\Device;

use Illuminate\Foundation\Http\FormRequest;

class StoreDeviceRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        return [
            'platform'     => ['required', 'in:ios,android,web'],
            'push_token'   => ['required', 'string', 'min:10', 'max:512'],
            'app_version'  => ['nullable', 'string', 'max:32'],
            'os_version'   => ['nullable', 'string', 'max:32'],
            'device_model' => ['nullable', 'string', 'max:64'],
            'locale'       => ['nullable', 'string', 'size:2'],
        ];
    }
}