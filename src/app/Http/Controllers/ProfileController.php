<?php

namespace App\Http\Controllers;

use App\Models\Profile;
use Illuminate\Http\Request;

class ProfileController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index()
    {
        //
    }

    /**
     * Show the form for creating a new resource.
     */
    public function create()
    {
        //
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(Request $request)
    {
        //
    }

    /**
     * Display the specified resource.
     */
    public function show(Profile $profile)
    {
        //
    }

    public function edit(Request $request)
    {
        $profile = $request->user()->profile ?? new Profile();
        return view('profile.edit', compact('profile'));
    }

    public function update(Request $request)
    {
        $data = $request->validate([
            'bio' => 'nullable|string|max:500',
            'avatar' => 'nullable|image',
            'timezone' => 'required|string',
        ]);

        $request->user()->profile()->updateOrCreate([], $data);

        return back()->with('status', 'Profile updated!');
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(Profile $profile)
    {
        //
    }
}
