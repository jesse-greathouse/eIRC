<?php

use Illuminate\Support\Facades\Route,
    Inertia\Inertia;

use App\Http\Controllers\ChatController;

Route::get('/', function () {
    return Inertia::render('Welcome');
})->name('home');

Route::get('dashboard', function () {
    return Inertia::render('Dashboard');
})->middleware(['auth', 'verified'])->name('dashboard');

Route::middleware(['auth'])->get('/chat', ChatController::class)->name('chat');

require __DIR__ . '/settings.php';
require __DIR__ . '/auth.php';
