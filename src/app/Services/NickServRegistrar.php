<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;

use App\Models\User;

class NickServRegistrar
{
    /**
     * Build the base URL for our IRC API endpoints.
     */
    protected function apiUrl(string $path): string
    {
        return rtrim(config('app.url'), '/') . '/irc/nickserv/' . ltrim($path, '/');
    }

    /**
     * Register a new user with NickServ.
     * Returns ['success'=>bool, 'responses'=>array<string>] or ['success'=>false,'error'=>string]
     */
    public function register(User $user): array
    {
        $chatToken = $this->makeChatToken($user);

        $response = Http::post(
            $this->apiUrl('register'),
            ['chat_token' => $chatToken]
        );

        if (! $response->successful()) {
            return ['success' => false, 'error' => $response->body()];
        }

        $data = $response->json();
        return [
            'success'   => $data['success'] ?? false,
            'responses' => $data['responses'] ?? [],
        ];
    }

    /**
     * Change the user's NickServ password to a new SASL secret.
     * Returns ['success'=>bool, 'responses'=>array<string>] or ['success'=>false,'error'=>string]
     */
    public function changePassword(User $user, string $newSecret): array
    {
        $chatToken = $this->makeChatToken($user);

        $payload = [
            'chat_token'       => $chatToken,
            'new_sasl_secret'  => $newSecret,
        ];

        $response = Http::post(
            $this->apiUrl('password'),
            $payload
        );

        if (! $response->successful()) {
            return ['success' => false, 'error' => $response->body()];
        }

        $data = $response->json();
        return [
            'success'   => $data['success'] ?? false,
            'responses' => $data['responses'] ?? [],
        ];
    }

    /**
     * Internal helper: generate and return a one-time chat_token.
     */
    protected function makeChatToken(User $user): string
    {
        return $user->createToken('chat')->token->id;
    }
}
