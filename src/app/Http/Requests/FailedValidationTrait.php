<?php

namespace App\Http\Requests;

use Illuminate\Contracts\Validation\Validator,
    Illuminate\Http\Exceptions\HttpResponseException,
    Illuminate\Validation\ValidationException;

/**
 * Provides a default implementation of failedValidation,
 * supporting both API and web requests.
 */
trait FailedValidationTrait
{
    public function failedValidation(Validator $validator)
    {
        if ($this->expectsJson()) {
            throw new HttpResponseException(response()->json([
                'success' => false,
                'message' => 'Validation errors',
                'data'    => $validator->errors(),
            ], 400));
        }

        throw (new ValidationException($validator))
            ->errorBag($this->errorBag)
            ->redirectTo($this->getRedirectUrl());
    }
}
