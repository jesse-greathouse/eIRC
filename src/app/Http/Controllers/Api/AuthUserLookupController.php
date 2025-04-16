<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;

use Illuminate\Http\JsonResponse;

use Laravel\Passport\Token;

class AuthUserLookupController extends Controller
{
    const TOKEN_TTL_MINUTES = 3;

    public function __invoke(string $tokenId): JsonResponse
    {
        $token = Token::find($tokenId);

        if (!$token || !$token->user) {
            abort(404, 'Token or user not found');
        }

        if ($token->created_at->diffInMinutes(now()) > self::TOKEN_TTL_MINUTES) {
            $token->delete();
            abort(401, 'Token expired');
        }

        // Copy the User object and delete the token
        $user = $token->user;
        $token->delete();
        return response()->json($user);
    }
}
