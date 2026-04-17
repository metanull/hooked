<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Middleware\TrustProxies as Middleware;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use RuntimeException;

class TrustProxies extends Middleware
{
    /**
     * Handle an incoming request.
     */
    public function handle(Request $request, Closure $next): mixed
    {
        $configuration = config('proxy');

        if (! is_array($configuration)) {
            throw new RuntimeException('Proxy configuration must be an array.');
        }

        $proxies = null;

        if (array_key_exists('proxies', $configuration)) {
            $proxies = $configuration['proxies'];
        }

        $headers = null;

        if (array_key_exists('headers', $configuration)) {
            $headers = $configuration['headers'];
        }

        $source = 'env';

        if (array_key_exists('source', $configuration) && is_string($configuration['source'])) {
            $source = $configuration['source'];
        }

        $sitePath = '';

        if (array_key_exists('site_path', $configuration) && is_string($configuration['site_path'])) {
            $sitePath = $configuration['site_path'];
        }

        $this->proxies = $this->normalizeProxies($proxies);
        $this->headers = $this->normalizeHeaders($headers);

        if ($source === 'site') {
            Log::info('TrustProxies loaded configuration from config/site/proxy.php.', [
                'site_path' => $sitePath,
                'proxies' => $this->proxies,
                'headers' => $this->headers,
            ]);
        } else {
            Log::warning('TrustProxies is using .env fallback because config/site/proxy.php was not found.', [
                'site_path' => $sitePath,
                'proxies' => $this->proxies,
                'headers' => $this->headers,
            ]);
        }

        return parent::handle($request, $next);
    }

    /**
     * Normalize trusted proxy definitions.
     *
     * @return array<int, string>|string
     */
    private function normalizeProxies(mixed $proxies): array|string
    {
        if (is_string($proxies)) {
            $trimmedValue = trim($proxies);

            if ($trimmedValue === '') {
                return [];
            }

            if ($trimmedValue === '*' || $trimmedValue === '**') {
                return $trimmedValue;
            }

            $proxyValues = explode(',', $trimmedValue);
            $normalizedValues = [];

            foreach ($proxyValues as $proxyValue) {
                $normalizedValue = trim($proxyValue);

                if ($normalizedValue !== '') {
                    $normalizedValues[] = $normalizedValue;
                }
            }

            return $normalizedValues;
        }

        if (is_array($proxies)) {
            $normalizedValues = [];

            foreach ($proxies as $proxyValue) {
                if (! is_string($proxyValue)) {
                    throw new RuntimeException('Each trusted proxy entry must be a string.');
                }

                $normalizedValue = trim($proxyValue);

                if ($normalizedValue !== '') {
                    $normalizedValues[] = $normalizedValue;
                }
            }

            return $normalizedValues;
        }

        if ($proxies === null) {
            return [];
        }

        throw new RuntimeException('Trusted proxies must be defined as a string, an array of strings, or null.');
    }

    /**
     * Normalize the configured proxy headers into a Symfony header bitmask.
     */
    private function normalizeHeaders(mixed $headers): int
    {
        if (is_int($headers)) {
            return $headers;
        }

        $headerNames = [];

        if (is_string($headers)) {
            $headerNames = explode(',', $headers);
        } elseif (is_array($headers)) {
            $headerNames = $headers;
        } elseif ($headers === null) {
            $headerNames = ['X-Forwarded-For', 'X-Forwarded-Proto'];
        } else {
            throw new RuntimeException('Trusted proxy headers must be defined as an integer, string, array of strings, or null.');
        }

        $normalizedHeaders = 0;

        foreach ($headerNames as $headerName) {
            if (! is_string($headerName)) {
                throw new RuntimeException('Each trusted proxy header entry must be a string.');
            }

            $normalizedHeaderName = strtolower(str_replace('_', '-', trim($headerName)));

            if ($normalizedHeaderName === '') {
                continue;
            }

            if ($normalizedHeaderName === 'header-x-forwarded-for' || $normalizedHeaderName === 'x-forwarded-for') {
                $normalizedHeaders |= Request::HEADER_X_FORWARDED_FOR;
                continue;
            }

            if ($normalizedHeaderName === 'header-x-forwarded-proto' || $normalizedHeaderName === 'x-forwarded-proto') {
                $normalizedHeaders |= Request::HEADER_X_FORWARDED_PROTO;
                continue;
            }

            throw new RuntimeException('Unsupported trusted proxy header: '.$headerName);
        }

        if ($normalizedHeaders === 0) {
            throw new RuntimeException('At least one trusted proxy header must be configured.');
        }

        return $normalizedHeaders;
    }
}