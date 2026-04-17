<?php

namespace App\Providers;

use App\Contracts\TrustedWebhookIpRangeProviderInterface;
use App\Services\PowerShellService;
use App\Services\Webhooks\AtlassianIpRangeProvider;
use App\Services\Webhooks\BitbucketWebhookProvider;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        $this->app->singleton(TrustedWebhookIpRangeProviderInterface::class, function (): TrustedWebhookIpRangeProviderInterface {
            $webhookConfiguration = config('webhooks');

            if (! is_array($webhookConfiguration)) {
                throw new \RuntimeException('Webhook configuration must be an array.');
            }

            $atlassianConfiguration = [];

            if (array_key_exists('atlassian', $webhookConfiguration) && is_array($webhookConfiguration['atlassian'])) {
                $atlassianConfiguration = $webhookConfiguration['atlassian'];
            }

            $ipWhitelistConfiguration = config('ip_whitelist');
            $configuredRanges = [];

            if (is_array($ipWhitelistConfiguration) && array_key_exists('addresses', $ipWhitelistConfiguration)) {
                $configuredRanges = $ipWhitelistConfiguration['addresses'];
            }

            $sourceUrl = 'https://ip-ranges.atlassian.com/';

            if (array_key_exists('ip_ranges_url', $atlassianConfiguration) && is_string($atlassianConfiguration['ip_ranges_url']) && trim($atlassianConfiguration['ip_ranges_url']) !== '') {
                $sourceUrl = trim($atlassianConfiguration['ip_ranges_url']);
            }

            $cacheKey = 'webhooks.atlassian_ip_ranges';

            if (array_key_exists('cache_key', $atlassianConfiguration) && is_string($atlassianConfiguration['cache_key']) && trim($atlassianConfiguration['cache_key']) !== '') {
                $cacheKey = trim($atlassianConfiguration['cache_key']);
            }

            $cacheTtlSeconds = 86400;

            if (array_key_exists('cache_ttl_seconds', $atlassianConfiguration)) {
                $cacheTtlSeconds = (int) $atlassianConfiguration['cache_ttl_seconds'];
            }

            return new AtlassianIpRangeProvider($sourceUrl, $cacheKey, $cacheTtlSeconds, $configuredRanges);
        });

        $this->app->singleton(BitbucketWebhookProvider::class, function (): BitbucketWebhookProvider {
            $webhookConfiguration = config('webhooks');

            if (! is_array($webhookConfiguration)) {
                throw new \RuntimeException('Webhook configuration must be an array.');
            }

            $providersConfiguration = [];

            if (array_key_exists('providers', $webhookConfiguration) && is_array($webhookConfiguration['providers'])) {
                $providersConfiguration = $webhookConfiguration['providers'];
            }

            $bitbucketConfiguration = [];

            if (array_key_exists('bitbucket', $providersConfiguration) && is_array($providersConfiguration['bitbucket'])) {
                $bitbucketConfiguration = $providersConfiguration['bitbucket'];
            }

            $expectedUserAgent = 'Bitbucket-Webhooks/2.0';

            if (array_key_exists('user_agent', $bitbucketConfiguration) && is_string($bitbucketConfiguration['user_agent']) && trim($bitbucketConfiguration['user_agent']) !== '') {
                $expectedUserAgent = trim($bitbucketConfiguration['user_agent']);
            }

            $sharedSecret = null;

            if (array_key_exists('shared_secret', $bitbucketConfiguration) && is_string($bitbucketConfiguration['shared_secret']) && trim($bitbucketConfiguration['shared_secret']) !== '') {
                $sharedSecret = trim($bitbucketConfiguration['shared_secret']);
            }

            return new BitbucketWebhookProvider(
                $this->app->make(TrustedWebhookIpRangeProviderInterface::class),
                $expectedUserAgent,
                $sharedSecret,
            );
        });

        $this->app->singleton(PowerShellService::class, function (): PowerShellService {
            $configuration = config('powershell');

            if (! is_array($configuration)) {
                throw new \RuntimeException('PowerShell configuration must be an array.');
            }

            $executable = '';

            if (array_key_exists('executable', $configuration) && is_string($configuration['executable'])) {
                $executable = $configuration['executable'];
            }

            $launcherPath = null;

            if (array_key_exists('launcher_path', $configuration) && is_string($configuration['launcher_path']) && trim($configuration['launcher_path']) !== '') {
                $launcherPath = $configuration['launcher_path'];
            }

            $configurationSource = 'env';

            if (array_key_exists('source', $configuration) && is_string($configuration['source'])) {
                $configurationSource = $configuration['source'];
            }

            $sitePath = '';

            if (array_key_exists('site_path', $configuration) && is_string($configuration['site_path'])) {
                $sitePath = $configuration['site_path'];
            }

            $usedDefaultExecutable = false;

            if (array_key_exists('used_default_executable', $configuration)) {
                $usedDefaultExecutable = (bool) $configuration['used_default_executable'];
            }

            return new PowerShellService($executable, $launcherPath, $configurationSource, $sitePath, $usedDefaultExecutable);
        });
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        //
    }
}
