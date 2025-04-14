<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider,
    Laravel\Passport\Passport;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        // Laravel Passport setup.
        $keyPath = env('OAUTH_KEY_PATH', storage_path());
        Passport::loadKeysFrom($keyPath);
        Passport::hashClientSecrets();
    }
}
