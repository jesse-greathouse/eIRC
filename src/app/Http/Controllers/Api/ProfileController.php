<?php

namespace App\Http\Controllers\Api;

use Illuminate\Http\Request,
    Illuminate\Http\Response;

use App\Http\Controllers\Controller,
    App\Http\Resources\ProfileResource,
    App\Http\Resources\UserResource,
    App\Models\Profile,
    App\Models\User;

class ProfileController extends Controller
{
    public function show(Request $request, $realid)
    {
        // Validate realid format - adjust regex or rule as needed
        if (!preg_match('/^[a-zA-Z0-9_\-]{3,50}$/', $realid)) {
            return response()->json(['error' => 'Invalid profile identifier'], Response::HTTP_BAD_REQUEST);
        }

        // Optional: adjust logic to use eager loading and ProfileResource too
        $profile = Profile::with(['selectedAvatar', 'user'])
            ->whereHas('user', function ($query) use ($realid) {
                $query->where('realname', $realid);
            })
            ->first();

        if (!$profile) {
            return response()->json(['error' => 'Profile not found'], Response::HTTP_NOT_FOUND);
        }

        return new ProfileResource($profile);
    }

    /**
     * Get a profile by user's realname.
     */
    public function showByRealname(Request $request, $realname)
    {
        if (!preg_match('/^[a-zA-Z0-9_\-]{3,50}$/', $realname)) {
            return response()->json([
                'error' => 'Invalid profile identifier',
            ], 400);
        }

        $profile = Profile::with(['selectedAvatar', 'user'])
            ->whereHas('user', function ($query) use ($realname) {
                $query->where('realname', $realname);
            })
            ->first();

        if (!$profile) {
            return response()->json([
                'error' => 'Profile not found',
            ], 404);
        }

        return new ProfileResource($profile);
    }

    public function showUserWithProfile(Request $request, $realname)
    {
        $user = User::where('realname', $realname)
            ->with(['profile.selectedAvatar'])
            ->firstOrFail();

        return new UserResource($user);
    }
}
