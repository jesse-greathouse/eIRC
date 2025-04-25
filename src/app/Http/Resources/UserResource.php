<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class UserResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'realname' => $this->realname,
            'email' => $this->email,
            'profile' => $this->whenLoaded('profile', function () {
                return new ProfileResource($this->profile);
            }),
        ];
    }
}
