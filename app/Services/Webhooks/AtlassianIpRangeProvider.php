<?php

namespace App\Services\Webhooks;

use App\Contracts\TrustedWebhookIpRangeProviderInterface;
use Illuminate\Support\Facades\Http;
use RuntimeException;

class AtlassianIpRangeProvider implements TrustedWebhookIpRangeProviderInterface
{
    public function __construct(
        private readonly string $sourceUrl = 'https://ip-ranges.atlassian.com/',
    ) {}

    /**
     * @return array<int, string>
     */
    public function getRanges(): array
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
}