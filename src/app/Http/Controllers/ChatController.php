<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Inertia\Inertia;

class ChatController extends Controller
{
    public function __invoke(Request $request)
    {
        /** @var \App\Models\User $user */
        $user = Auth::user();

        $token = $user->tokens()
            ->where('name', 'Chat Client')
            ->where('revoked', false)
            ->latest()
            ->first();

        if (!$token) {
            $tokenResult = $user->createToken('Chat Client');
            $token = $tokenResult->token;
        }

        return Inertia::render('Chat', [
            'chat_token' => $token->id,
        ]);
    }
}
