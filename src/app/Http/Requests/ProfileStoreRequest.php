<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class ProfileStoreRequest extends FormRequest
{
    use FailedValidationTrait;

    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'bio' => ['nullable', 'string'],
            'timezone' => ['required', 'string', 'max:64'],
            'x_link' => ['nullable', 'url'],
            'instagram_link' => ['nullable', 'url'],
            'tiktok_link' => ['nullable', 'url'],
            'youtube_link' => ['nullable', 'url'],
            'facebook_link' => ['nullable', 'url'],
            'pinterest_link' => ['nullable', 'url'],
            'selected_avatar_id' => ['nullable', 'exists:avatars,id'],
        ];
    }
}
