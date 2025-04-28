<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller,
    App\Http\Requests\UserUpdateRequest,
    App\Http\Resources\UserResource,
    App\Models\User;

class UserUpdateController extends Controller
{
    public function __invoke(UserUpdateRequest $request, $realname)
    {
        $user = User::where('realname', $realname)->firstOrFail();

        $validated = $request->validated();

        // Manually serialize the array if channels is present
        if (isset($validated['channels']) && is_array($validated['channels'])) {
            $validated['channels'] = implode(',', $validated['channels']);
        }

        $user->fill($validated);
        $user->save();

        return new UserResource($user->load('profile'));
    }
}
