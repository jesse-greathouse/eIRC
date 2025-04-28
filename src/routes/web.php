<?php

use Illuminate\Support\Facades\Route,
    Inertia\Inertia;

use App\Http\Controllers\ChatController,
    App\Http\Controllers\ProfileController;

Route::get('/', function () {
    return Inertia::render('Dashboard');
})->middleware(['auth', 'verified'])->name('dashboard');

Route::get('/chat', ChatController::class)->name('chat')
    ->middleware(['auth'])
    ->name('chat.show');

Route::get('/profile/{realname}', ProfileController::class)
    ->middleware(['auth'])
    ->name('profile.show');

require __DIR__ . '/settings.php';
require __DIR__ . '/auth.php';
