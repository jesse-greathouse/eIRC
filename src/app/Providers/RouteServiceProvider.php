<?php

namespace App\Providers;

use Illuminate\Cache\RateLimiting\Limit,
    Illuminate\Support\Facades\RateLimiter,
    Illuminate\Support\Facades\Route,
    Illuminate\Foundation\Support\Providers\RouteServiceProvider as ServiceProvider;


class RouteServiceProvider extends ServiceProvider
{
    protected $policies = [];

    public function boot()
    {
        RateLimiter::for('profile_lookup', function ($request) {
            return Limit::perSecond(10)->by($request->ip());
        });

        $this->routes(function () {
            Route::middleware('api')
                ->prefix('api')
                ->group(base_path('routes/api.php'));

            Route::middleware('web')
                ->group(base_path('routes/web.php'));
        });
    }
}
