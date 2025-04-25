<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ProfileResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'bio' => $this->bio,
            'timezone' => $this->timezone,
            'x_link' => $this->x_link,
            'instagram_link' => $this->instagram_link,
            'tiktok_link' => $this->tiktok_link,
            'youtube_link' => $this->youtube_link,
            'facebook_link' => $this->facebook_link,
            'pinterest_link' => $this->pinterest_link,
            'selected_avatar_id' => $this->selected_avatar_id,
            'selected_avatar' => $this->whenLoaded('selectedAvatar', function () {
                return new AvatarResource($this->selectedAvatar);
            }),
            'user' => $this->whenLoaded('user', function () {
                return new UserShallowResource($this->user);
            }),
        ];
    }
}
