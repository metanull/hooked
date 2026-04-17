<?php

namespace App\Services\Webhooks;

use App\Contracts\WebhookProviderInterface;
use Illuminate\Support\Facades\Log;

class WebhookProviderManager
{
    public function __construct(
        private readonly BitbucketWebhookProvider $bitbucketWebhookProvider,
    ) {}

    public function resolve(string $providerName): ?WebhookProviderInterface
    {
        if ($providerName === $this->bitbucketWebhookProvider->getProviderName()) {
            return $this->bitbucketWebhookProvider;
        }

        Log::warning('Webhook provider could not be resolved.', [
            'provider' => $providerName,
        ]);

        return null;
    }
}