<?php

namespace App\Http\Controllers;

use App\Models\Avatar;
use Illuminate\Http\Request;

class AvatarController extends Controller
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
        $request->validate([
            'avatar' => 'required|image|max:2048', // Max 2MB
        ]);

        $image = $request->file('avatar');
        $mimeType = $image->getMimeType(); // e.g., image/png
        $contents = file_get_contents($image->getRealPath());

        $base64 = base64_encode($contents);
        $base64Data = "data:$mimeType;base64,$base64";

        // Save avatar immediately
        $avatar = new Avatar([
            'base64_data' => $base64Data,
            'is_active' => true, // or set logic for active avatar
        ]);

        $request->user()->avatars()->save($avatar);

        return back()->with('status', 'Avatar uploaded successfully!');
    }

    /**
     * Display the specified resource.
     */
    public function show(Avatar $avatar)
    {
        //
    }

    /**
     * Show the form for editing the specified resource.
     */
    public function edit(Avatar $avatar)
    {
        //
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(Request $request, Avatar $avatar)
    {
        //
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(Avatar $avatar)
    {
        //
    }
}
