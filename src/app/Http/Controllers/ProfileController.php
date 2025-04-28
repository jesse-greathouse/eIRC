<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request,
    Inertia\Inertia;

use Symfony\Component\HttpKernel\Exception\NotFoundHttpException;

use App\Models\Profile;


class ProfileController extends Controller
{
    public function __invoke(Request $request, string $realname)
    {
        if (!preg_match('/^[a-zA-Z0-9_\-]{3,50}$/', $realname)) {
            throw new NotFoundHttpException('Invalid profile identifier.');
        }

        $profile = Profile::with(['selectedAvatar', 'user'])
            ->whereHas('user', function ($query) use ($realname) {
                $query->where('realname', $realname);
            })
            ->first();

        if (!$profile) {
            throw new NotFoundHttpException('Profile not found.');
        }

        return Inertia::render('Profile', [
            'profile' => $profile,
            'user' => $profile->user,
        ]);
    }
}
