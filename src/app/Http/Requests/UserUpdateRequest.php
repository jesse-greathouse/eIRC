<?php

namespace App\Http\Requests;

use App\Http\Requests\FailedValidationTrait;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UserUpdateRequest extends FormRequest
{
    use FailedValidationTrait;

    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'name' => ['required', 'string', 'max:255'],
            'email' => [
                'required',
                'string',
                'lowercase',
                'email',
                'max:255',
                Rule::unique('users', 'email')->ignore($this->user()->id),
            ],
            'nick' => ['nullable', 'string', 'min:4', 'max:255', 'regex:/^[A-Za-z0-9_]+$/'],
            'settings' => ['nullable', 'array'],
        ];
    }
}
