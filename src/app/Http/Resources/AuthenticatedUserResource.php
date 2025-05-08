<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class AuthenticatedUserResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'realname' => $this->realname,
            'nick' => $this->nick,
            'email' => $this->email,
            'sasl_secret'  => $this->sasl_secret,
            'channels' => $this->formatChannels(),
            'profile' => $this->whenLoaded('profile', function () {
                return [
                    'bio' => $this->profile->bio,
                    'timezone' => $this->profile->timezone,
                    'x_link' => $this->profile->x_link,
                    'instagram_link' => $this->profile->instagram_link,
                    'tiktok_link' => $this->profile->tiktok_link,
                    'youtube_link' => $this->profile->youtube_link,
                    'facebook_link' => $this->profile->facebook_link,
                    'pinterest_link' => $this->profile->pinterest_link,
                    'avatar_url' => $this->profile->selectedAvatar
                        ? $this->profile->selectedAvatar->base64_data
                        : null,
                ];
            }),
        ];
    }

    private function formatChannels()
    {
        if (is_array($this->channels)) {
            return $this->channels;
        }

        if (is_string($this->channels)) {
            return explode(',', $this->channels);
        }

        return [];
    }
}
