<?php

namespace App\Http\Controllers\Api;

use Illuminate\Http\JsonResponse;

use Laravel\Passport\Token;

use App\Http\Controllers\Controller,
    App\Http\Resources\AuthenticatedUserResource;

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

        $user = $token->user()->with(['profile.selectedAvatar'])->first();
        $token->delete();

        return response()->json(new AuthenticatedUserResource($user));
    }
}
