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
    App\Models\Profile;

class ProfileController extends Controller
{
    /**
     * Show the user's profile settings page.
     */
    public function edit(Request $request): Response
    {
        $user = $request->user();
        $profile = $user->profile ?? new Profile(['user_id' => $user->id]);

        return Inertia::render('settings/Profile', [
            'mustVerifyEmail' => $user instanceof MustVerifyEmail,
            'status' => $request->session()->get('status'),
            'user' => $user,
            'profile' => $profile,
        ]);
    }

    /**
     * Update the user's profile information.
     */
    public function update(ProfileUpdateRequest $request): RedirectResponse
    {
        $user = $request->user();

        if ($user->isDirty('email')) {
            $user->email_verified_at = null;
        }

        $profile = $user->profile ?? new Profile(['user_id' => $user->id]);

        $profile->fill($request->validated());
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
