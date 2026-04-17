<?php

namespace App\DataTransferObjects;

final readonly class WebhookPayload
{
    /**
     * @param  array<string, mixed>  $rawPayload
     */
    public function __construct(
        public string $repositorySlug,
        public string $branch,
        public string $actor,
        public array $rawPayload,
    ) {}
}