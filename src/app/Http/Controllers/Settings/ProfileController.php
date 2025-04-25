<?php

namespace App\Http\Controllers\Settings;

use Illuminate\Contracts\Auth\MustVerifyEmail,
    Illuminate\Http\RedirectResponse,
    Illuminate\Http\Request,
    Illuminate\Support\Facades\Auth;

use Inertia\Inertia,
    Inertia\Response;

use App\Http\Controllers\Controller,
    App\Http\Requests\ProfileUpdateRequest,
    App\Models\Avatar,
    App\Models\Profile;

class ProfileController extends Controller
{
    /**
     * Show the user's account settings page.
     */
    public function account(Request $request): \Inertia\Response
    {
        return Inertia::render('settings/Account', [
            'mustVerifyEmail' => $request->user() instanceof MustVerifyEmail,
            'status' => $request->session()->get('status'),
            'user' => $request->user(),
        ]);
    }

    public function edit(Request $request): Response
    {
        $user = $request->user();

        // Ensure profile exists
        $profile = $user->profile ?? new Profile(['user_id' => $user->id]);

        // Eager load selectedAvatar relationship
        $profile->load('selectedAvatar');

        return Inertia::render('settings/Profile', [
            'user' => $user,
            'profile' => $profile,
        ]);
    }

    /**
     * Update the user's profile information.
     */
    public function update(ProfileUpdateRequest $request): RedirectResponse
    {
        // Get the authenticated user from session
        $user = $request->user();

        // Either get existing profile or create a new one
        $profile = $user->profile ?? new Profile();

        // Always associate profile with session user
        $profile->user_id = $user->id;

        // Fill in validated profile data
        $profile->fill($request->validated());

        // Handle avatar upload
        if ($request->hasFile('avatar')) {
            $file = $request->file('avatar');

            // Get file contents and mime type
            $contents = file_get_contents($file->getRealPath());
            $mimeType = $file->getMimeType();

            // Convert to base64 data URI
            $base64Data = 'data:' . $mimeType . ';base64,' . base64_encode($contents);

            // Save as a new Avatar
            $avatar = new Avatar();
            $avatar->profile_id = $profile->id;
            $avatar->base64_data = $base64Data;
            $avatar->save();

            // Optionally, set as selected avatar
            $profile->selected_avatar_id = $avatar->id;
            $profile->save();
        }

        $profile->save();

        return to_route('profile.edit')->with('status', 'profile-updated');
    }

    /**
     * Delete the user's profile.
     */
    public function destroy(Request $request): RedirectResponse
    {
        $request->validate([
            'password' => ['required', 'current_password'],
        ]);

        $user = $request->user();

        Auth::logout();

        $user->delete();

        $request->session()->invalidate();
        $request->session()->regenerateToken();

        return redirect('/');
    }
}
