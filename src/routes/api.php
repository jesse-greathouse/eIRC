<?php

use Illuminate\Http\Request,
    Illuminate\Support\Facades\Route;

use App\Http\Controllers\Api\AuthUserLookupController;

Route::get('/user', function (Request $request) {
    return $request->user();
})->middleware('auth:api');


Route::get('/auth/user/{tokenId}', AuthUserLookupController::class);
