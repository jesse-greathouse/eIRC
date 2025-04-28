<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller,
    App\Http\Resources\UserResource,
    App\Models\User;

class UserController extends Controller
{
    public function show($realname)
    {
        $user = User::where('realname', $realname)->firstOrFail();

        return new UserResource($user->load('profile'));
    }
}
