<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest,
    Illuminate\Validation\Rule;

use App\Http\Requests\FailedValidationTrait,
    App\Models\User;

class UserUpdateRequest extends FormRequest
{
    use FailedValidationTrait;

    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        $userId = $this->route('realname')
            ? optional(User::where('realname', $this->route('realname'))->first())->id
            : $this->user()?->id;

        return [
            'name' => ['sometimes', 'required', 'string', 'max:255'],
            'email' => [
                'sometimes',
                'required',
                'string',
                'lowercase',
                'email',
                'max:255',
                Rule::unique('users', 'email')->ignore($userId),
            ],
            'nick' => ['nullable', 'string', 'min:4', 'max:255', 'regex:/^[A-Za-z0-9_]+$/'],
            'settings' => ['nullable', 'array'],
            'realname' => ['nullable', 'string', 'max:255'],
            'channels' => ['nullable', 'array'],
        ];
    }
}
