<?php

use Illuminate\Http\Request,
    Illuminate\Support\Facades\Route;

use App\Http\Controllers\Api\AuthUserLookupController,
    App\Http\Controllers\Api\ProfileController;

Route::get('/user', function (Request $request) {
    return $request->user();
})->middleware('auth:api');

Route::get('/auth/user/{tokenId}', AuthUserLookupController::class);

Route::middleware(['web', 'auth'])->group(function () {
    Route::get('/profile/{realname}', [ProfileController::class, 'showByRealname']);
});
