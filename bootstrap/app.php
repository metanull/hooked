<?php

use App\Http\Middleware\EnforceIpWhitelist;
use App\Http\Middleware\TrustProxies;
use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Illuminate\Http\Middleware\TrustProxies as IlluminateTrustProxies;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware): void {
        $middleware->replace(IlluminateTrustProxies::class, TrustProxies::class);
        $middleware->appendToGroup('web', EnforceIpWhitelist::class);
    })
    ->withExceptions(function (Exceptions $exceptions): void {
        //
    })->create();
