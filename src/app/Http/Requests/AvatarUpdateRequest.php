<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class AvatarUpdateRequest extends FormRequest
{
    use FailedValidationTrait;

    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'avatar_file' => ['required', 'file', 'image', 'max:2048'], // 2MB max
        ];
    }

    public function messages(): array
    {
        return [
            'avatar_file.image' => 'The uploaded file must be a valid image.',
            'avatar_file.max' => 'The image must not exceed 2MB.',
        ];
    }
}
