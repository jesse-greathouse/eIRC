<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;

use App\Models\User;

class NickServRegistrar
{
    /**
     * Call the Lua /irc/nickserv/register endpoint
     * Returns ['success'=>bool, 'responses'=>array<string>] or ['success'=>false,'error'=>string]
     */
    public function register(User $user): array
    {
        // Generate a fresh chat_token
        $tokenModel = $user->createToken('chat')->token;
        $chatToken  = $tokenModel->id;

        $url = config('app.url') . '/irc/nickserv/register';
        $response = Http::post($url, ['chat_token' => $chatToken]);

        if (! $response->successful()) {
            return ['success' => false, 'error' => $response->body()];
        }

        $data = $response->json();
        return [
            'success'   => $data['success'] ?? false,
            'responses' => $data['responses'] ?? [],
        ];
    }
}
