<?php

namespace Tests\Feature;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use Tests\TestCase;

class TrustProxiesTest extends TestCase
{
    public function test_trusted_proxy_headers_are_applied_for_a_configured_proxy(): void
    {
        config()->set('proxy', [
            'source' => 'env',
            'site_path' => base_path('config/site/proxy.php'),
            'proxies' => '127.0.0.1',
            'headers' => 'X-Forwarded-For,X-Forwarded-Proto',
        ]);

        Route::middleware(\App\Http\Middleware\TrustProxies::class)->get('/proxy-test', function (Request $request) {
            return response()->json([
                'ip' => $request->ip(),
                'scheme' => $request->getScheme(),
            ]);
        });

        $response = $this
            ->withServerVariables([
                'REMOTE_ADDR' => '127.0.0.1',
                'HTTP_X_FORWARDED_FOR' => '203.0.113.10',
                'HTTP_X_FORWARDED_PROTO' => 'https',
            ])
            ->get('/proxy-test');

        $response->assertOk();
        $response->assertJson([
            'ip' => '203.0.113.10',
            'scheme' => 'https',
        ]);
    }
}