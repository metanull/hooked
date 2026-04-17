<?php

namespace Tests\Feature;

use Illuminate\Support\Facades\Route;
use Tests\TestCase;

class IpWhitelistTest extends TestCase
{
    public function test_whitelist_allows_a_client_ip_inside_a_cidr_range(): void
    {
        config()->set('ip_whitelist', [
            'source' => 'env',
            'site_path' => base_path('config/site/ip-whitelist.php'),
            'enabled' => true,
            'addresses' => '10.0.0.0/8',
        ]);

        Route::middleware('web')->get('/ip-whitelist-test', function () {
            return response('ok');
        });

        $response = $this
            ->withServerVariables([
                'REMOTE_ADDR' => '10.10.10.10',
            ])
            ->get('/ip-whitelist-test');

        $response->assertOk();
    }

    public function test_whitelist_blocks_a_client_ip_outside_the_configured_ranges(): void
    {
        config()->set('ip_whitelist', [
            'source' => 'env',
            'site_path' => base_path('config/site/ip-whitelist.php'),
            'enabled' => true,
            'addresses' => '10.0.0.0/8',
        ]);

        Route::middleware('web')->get('/ip-whitelist-blocked-test', function () {
            return response('ok');
        });

        $response = $this
            ->withServerVariables([
                'REMOTE_ADDR' => '192.168.1.50',
            ])
            ->get('/ip-whitelist-blocked-test');

        $response->assertForbidden();
    }

    public function test_whitelist_can_be_disabled(): void
    {
        config()->set('ip_whitelist', [
            'source' => 'env',
            'site_path' => base_path('config/site/ip-whitelist.php'),
            'enabled' => false,
            'addresses' => '10.0.0.0/8',
        ]);

        Route::middleware('web')->get('/ip-whitelist-disabled-test', function () {
            return response('ok');
        });

        $response = $this
            ->withServerVariables([
                'REMOTE_ADDR' => '192.168.1.50',
            ])
            ->get('/ip-whitelist-disabled-test');

        $response->assertOk();
    }
}