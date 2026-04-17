<?php

namespace App\Http\Middleware;

use App\Support\Ipv4Range;
use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use RuntimeException;
use Symfony\Component\HttpFoundation\Response;

class EnforceIpWhitelist
{
    /**
     * Handle an incoming request.
     */
    public function handle(Request $request, Closure $next): Response
    {
        $configuration = config('ip_whitelist');

        if (! is_array($configuration)) {
            throw new RuntimeException('IP whitelist configuration must be an array.');
        }

        $enabled = false;

        if (array_key_exists('enabled', $configuration)) {
            $enabled = (bool) $configuration['enabled'];
        }

        $source = 'env';

        if (array_key_exists('source', $configuration) && is_string($configuration['source'])) {
            $source = $configuration['source'];
        }

        $sitePath = '';

        if (array_key_exists('site_path', $configuration) && is_string($configuration['site_path'])) {
            $sitePath = $configuration['site_path'];
        }

        $addresses = [];

        if (array_key_exists('addresses', $configuration)) {
            $addresses = $this->normalizeAddresses($configuration['addresses']);
        }

        if (! $enabled) {
            Log::info('IP whitelist middleware is disabled.', [
                'source' => $source,
                'site_path' => $sitePath,
            ]);

            return $next($request);
        }

        if ($source === 'site') {
            Log::info('IP whitelist loaded configuration from config/site/ip-whitelist.php.', [
                'site_path' => $sitePath,
                'addresses' => $addresses,
            ]);
        } else {
            Log::warning('IP whitelist is using .env fallback because config/site/ip-whitelist.php was not found.', [
                'site_path' => $sitePath,
                'addresses' => $addresses,
            ]);
        }

        $clientIp = $request->ip();

        if (! is_string($clientIp) || $clientIp === '') {
            Log::warning('IP whitelist blocked a request because the client IP could not be resolved.');
            abort(403, 'Client IP address could not be resolved.');
        }

        if (! Ipv4Range::matchesAny($clientIp, $addresses)) {
            Log::warning('IP whitelist blocked a request.', [
                'client_ip' => $clientIp,
                'addresses' => $addresses,
            ]);

            abort(403, 'Client IP address is not allowed.');
        }

        return $next($request);
    }

    /**
     * Normalize configured whitelist addresses.
     *
     * @return array<int, string>
     */
    private function normalizeAddresses(mixed $addresses): array
    {
        if (is_string($addresses)) {
            $addressParts = explode(',', $addresses);
            $normalizedAddresses = [];

            foreach ($addressParts as $addressPart) {
                $normalizedAddress = trim($addressPart);

                if ($normalizedAddress !== '') {
                    $normalizedAddresses[] = $normalizedAddress;
                }
            }

            return $normalizedAddresses;
        }

        if (is_array($addresses)) {
            $normalizedAddresses = [];

            foreach ($addresses as $address) {
                if (! is_string($address)) {
                    throw new RuntimeException('Each IP whitelist entry must be a string.');
                }

                $normalizedAddress = trim($address);

                if ($normalizedAddress !== '') {
                    $normalizedAddresses[] = $normalizedAddress;
                }
            }

            return $normalizedAddresses;
        }

        if ($addresses === null) {
            return [];
        }

        throw new RuntimeException('IP whitelist addresses must be defined as a string, an array of strings, or null.');
    }
}