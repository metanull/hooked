<?php

namespace App\Services\Webhooks;

use App\Contracts\TrustedWebhookIpRangeProviderInterface;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use RuntimeException;

class AtlassianIpRangeProvider implements TrustedWebhookIpRangeProviderInterface
{
    public function __construct(
        private readonly string $sourceUrl = 'https://ip-ranges.atlassian.com/',
        private readonly string $cacheKey = 'webhooks.atlassian_ip_ranges',
        private readonly int $freshForSeconds = 86400,
        mixed $configuredRanges = [],
    ) {
        $this->configuredRanges = $this->normalizeConfiguredRanges($configuredRanges);
    }

    /**
     * @var array<int, string>
     */
    private readonly array $configuredRanges;

    /**
     * @return array<int, string>
     */
    public function getRanges(): array
    {
        $cachedPayload = Cache::get($this->cacheKey);
        $cachedRanges = [];
        $cacheAgeInSeconds = null;

        if (is_array($cachedPayload)) {
            $cachedRanges = $this->extractCachedRanges($cachedPayload);
            $cacheAgeInSeconds = $this->extractCacheAgeInSeconds($cachedPayload);

            if ($cacheAgeInSeconds !== null && $cacheAgeInSeconds <= $this->freshForSeconds) {
                Log::info('Using fresh cached Atlassian IP ranges.', [
                    'cache_key' => $this->cacheKey,
                    'cache_age_in_seconds' => $cacheAgeInSeconds,
                    'configured_ranges' => $this->configuredRanges,
                    'cached_range_count' => count($cachedRanges),
                ]);

                return $this->mergeRanges($this->configuredRanges, $cachedRanges);
            }

            if ($cacheAgeInSeconds !== null) {
                Log::info('Cached Atlassian IP ranges are stale and will be refreshed.', [
                    'cache_key' => $this->cacheKey,
                    'cache_age_in_seconds' => $cacheAgeInSeconds,
                ]);
            }
        }

        try {
            $fetchedRanges = $this->fetchRangesFromSource();
        } catch (RuntimeException $exception) {
            if ($cachedRanges !== []) {
                Log::warning('Using stale cached Atlassian IP ranges because the live fetch failed.', [
                    'cache_key' => $this->cacheKey,
                    'cache_age_in_seconds' => $cacheAgeInSeconds,
                    'message' => $exception->getMessage(),
                ]);

                return $this->mergeRanges($this->configuredRanges, $cachedRanges);
            }

            Log::warning('Skipping Atlassian IP ranges because the live fetch failed and no cache is available.', [
                'cache_key' => $this->cacheKey,
                'message' => $exception->getMessage(),
                'configured_ranges' => $this->configuredRanges,
            ]);

            return $this->configuredRanges;
        }

        Cache::forever($this->cacheKey, [
            'fetched_at' => now()->timestamp,
            'ranges' => $fetchedRanges,
        ]);

        Log::info('Fetched and cached Atlassian IP ranges.', [
            'cache_key' => $this->cacheKey,
            'range_count' => count($fetchedRanges),
            'configured_ranges' => $this->configuredRanges,
        ]);

        return $this->mergeRanges($this->configuredRanges, $fetchedRanges);
    }

    /**
     * @return array<int, string>
     */
    private function fetchRangesFromSource(): array
    {
        $response = Http::timeout(5)->get($this->sourceUrl);

        if (! $response->successful()) {
            throw new RuntimeException('Unable to load Atlassian IP ranges.');
        }

        $payload = $response->json();

        if (! is_array($payload)) {
            throw new RuntimeException('Atlassian IP range response must decode to an array.');
        }

        if (! array_key_exists('items', $payload) || ! is_array($payload['items'])) {
            throw new RuntimeException('Atlassian IP range response must include an items array.');
        }

        $ranges = [];

        foreach ($payload['items'] as $item) {
            if (! is_array($item)) {
                continue;
            }

            if (! array_key_exists('cidr', $item) || ! is_string($item['cidr'])) {
                continue;
            }

            $cidr = trim($item['cidr']);

            if ($cidr === '' || str_contains($cidr, ':')) {
                continue;
            }

            $ranges[] = $cidr;
        }

        return $ranges;
    }

    /**
     * @param  mixed  $configuredRanges
     * @return array<int, string>
     */
    private function normalizeConfiguredRanges(mixed $configuredRanges): array
    {
        if (is_string($configuredRanges)) {
            $configuredRanges = explode(',', $configuredRanges);
        }

        if ($configuredRanges === null) {
            return [];
        }

        if (! is_array($configuredRanges)) {
            throw new RuntimeException('Configured trusted webhook IP ranges must be a string, an array, or null.');
        }

        $normalizedRanges = [];

        foreach ($configuredRanges as $configuredRange) {
            if (! is_string($configuredRange)) {
                throw new RuntimeException('Each configured trusted webhook IP range must be a string.');
            }

            $normalizedRange = trim($configuredRange);

            if ($normalizedRange !== '') {
                $normalizedRanges[] = $normalizedRange;
            }
        }

        return array_values(array_unique($normalizedRanges));
    }

    /**
     * @param  array<string, mixed>  $cachedPayload
     * @return array<int, string>
     */
    private function extractCachedRanges(array $cachedPayload): array
    {
        if (! array_key_exists('ranges', $cachedPayload) || ! is_array($cachedPayload['ranges'])) {
            return [];
        }

        return $this->normalizeConfiguredRanges($cachedPayload['ranges']);
    }

    /**
     * @param  array<string, mixed>  $cachedPayload
     */
    private function extractCacheAgeInSeconds(array $cachedPayload): ?int
    {
        if (! array_key_exists('fetched_at', $cachedPayload) || ! is_int($cachedPayload['fetched_at'])) {
            return null;
        }

        return now()->timestamp - $cachedPayload['fetched_at'];
    }

    /**
     * @param  array<int, string>  $configuredRanges
     * @param  array<int, string>  $fetchedRanges
     * @return array<int, string>
     */
    private function mergeRanges(array $configuredRanges, array $fetchedRanges): array
    {
        return array_values(array_unique(array_merge($configuredRanges, $fetchedRanges)));
    }
}