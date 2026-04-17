<?php

namespace Tests\Unit\Webhooks;

use App\Services\Webhooks\AtlassianIpRangeProvider;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class AtlassianIpRangeProviderTest extends TestCase
{
    protected function tearDown(): void
    {
        Cache::flush();

        parent::tearDown();
    }

    public function test_it_fetches_caches_and_merges_ranges_with_configured_trusted_ips(): void
    {
        Http::fake([
            'https://ip-ranges.atlassian.com/' => Http::response([
                'items' => [
                    ['cidr' => '104.192.136.0/21'],
                    ['cidr' => '2401:1d80::/32'],
                ],
            ]),
        ]);

        $provider = new AtlassianIpRangeProvider(
            'https://ip-ranges.atlassian.com/',
            'tests.webhooks.atlassian_ip_ranges',
            86400,
            ['127.0.0.1', '10.0.0.0/8'],
        );

        $ranges = $provider->getRanges();

        $this->assertSame(['127.0.0.1', '10.0.0.0/8', '104.192.136.0/21'], $ranges);
        $this->assertSame([
            'fetched_at' => now()->timestamp,
            'ranges' => ['104.192.136.0/21'],
        ], Cache::get('tests.webhooks.atlassian_ip_ranges'));
    }

    public function test_it_uses_a_fresh_cache_entry_without_calling_the_remote_service(): void
    {
        Cache::forever('tests.webhooks.atlassian_ip_ranges', [
            'fetched_at' => now()->subHour()->timestamp,
            'ranges' => ['104.192.136.0/21'],
        ]);
        Http::fake();
        $provider = new AtlassianIpRangeProvider(
            'https://ip-ranges.atlassian.com/',
            'tests.webhooks.atlassian_ip_ranges',
            86400,
            ['10.0.0.0/8'],
        );

        $ranges = $provider->getRanges();

        $this->assertSame(['10.0.0.0/8', '104.192.136.0/21'], $ranges);
        Http::assertNothingSent();
    }

    public function test_it_uses_stale_cache_when_the_remote_fetch_fails(): void
    {
        Cache::forever('tests.webhooks.atlassian_ip_ranges', [
            'fetched_at' => now()->subDays(2)->timestamp,
            'ranges' => ['104.192.136.0/21'],
        ]);
        Http::fake([
            'https://ip-ranges.atlassian.com/' => Http::response('unavailable', 500),
        ]);
        $provider = new AtlassianIpRangeProvider(
            'https://ip-ranges.atlassian.com/',
            'tests.webhooks.atlassian_ip_ranges',
            86400,
            ['10.0.0.0/8'],
        );

        $ranges = $provider->getRanges();

        $this->assertSame(['10.0.0.0/8', '104.192.136.0/21'], $ranges);
    }

    public function test_it_returns_only_configured_ranges_when_fetch_fails_and_no_cache_exists(): void
    {
        Http::fake([
            'https://ip-ranges.atlassian.com/' => Http::response('unavailable', 500),
        ]);
        $provider = new AtlassianIpRangeProvider(
            'https://ip-ranges.atlassian.com/',
            'tests.webhooks.atlassian_ip_ranges',
            86400,
            ['127.0.0.1', '10.0.0.0/8'],
        );

        $ranges = $provider->getRanges();

        $this->assertSame(['127.0.0.1', '10.0.0.0/8'], $ranges);
    }
}