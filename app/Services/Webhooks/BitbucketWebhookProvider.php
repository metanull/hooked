<?php

namespace App\Services\Webhooks;

use App\Contracts\TrustedWebhookIpRangeProviderInterface;
use App\Contracts\WebhookProviderInterface;
use App\DataTransferObjects\WebhookPayload;
use App\Support\Ipv4Range;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use RuntimeException;

class BitbucketWebhookProvider implements WebhookProviderInterface
{
    public function __construct(
        private readonly TrustedWebhookIpRangeProviderInterface $trustedIpRangeProvider,
        private readonly string $expectedUserAgent = 'Bitbucket-Webhooks/2.0',
        private readonly ?string $sharedSecret = null,
    ) {}

    public function validateRequest(Request $request): bool
    {
        $userAgent = $request->userAgent();

        if (! is_string($userAgent) || $userAgent !== $this->expectedUserAgent) {
            Log::warning('Bitbucket webhook request rejected because the user agent was invalid.', [
                'provider' => $this->getProviderName(),
                'expected_user_agent' => $this->expectedUserAgent,
                'actual_user_agent' => $userAgent,
            ]);

            return false;
        }

        $clientIp = $request->ip();

        if (! is_string($clientIp) || $clientIp === '') {
            Log::warning('Bitbucket webhook request rejected because the client IP could not be resolved.', [
                'provider' => $this->getProviderName(),
            ]);

            return false;
        }

        $trustedRanges = $this->trustedIpRangeProvider->getRanges();

        if (! Ipv4Range::matchesAny($clientIp, $trustedRanges)) {
            Log::warning('Bitbucket webhook request rejected because the client IP is not trusted.', [
                'provider' => $this->getProviderName(),
                'client_ip' => $clientIp,
                'trusted_ranges' => $trustedRanges,
            ]);

            return false;
        }

        if (! is_string($this->sharedSecret) || trim($this->sharedSecret) === '') {
            Log::info('Bitbucket webhook request accepted without HMAC validation because no shared secret is configured.', [
                'provider' => $this->getProviderName(),
                'client_ip' => $clientIp,
            ]);

            return true;
        }

        $signatureHeader = $request->header('X-Hub-Signature');

        if (! is_string($signatureHeader) || $signatureHeader === '') {
            Log::warning('Bitbucket webhook request rejected because the X-Hub-Signature header is missing.', [
                'provider' => $this->getProviderName(),
                'client_ip' => $clientIp,
            ]);

            return false;
        }

        if (! str_starts_with($signatureHeader, 'sha256=')) {
            Log::warning('Bitbucket webhook request rejected because the X-Hub-Signature header format is invalid.', [
                'provider' => $this->getProviderName(),
                'client_ip' => $clientIp,
                'signature_header' => $signatureHeader,
            ]);

            return false;
        }

        $computedSignature = hash_hmac('sha256', $request->getContent(), $this->sharedSecret);
        $receivedSignature = substr($signatureHeader, 7);

        if (! is_string($receivedSignature) || $receivedSignature === '') {
            Log::warning('Bitbucket webhook request rejected because the X-Hub-Signature header did not contain a digest.', [
                'provider' => $this->getProviderName(),
                'client_ip' => $clientIp,
            ]);

            return false;
        }

        if (! hash_equals($computedSignature, $receivedSignature)) {
            Log::warning('Bitbucket webhook request rejected because the HMAC digest did not match.', [
                'provider' => $this->getProviderName(),
                'client_ip' => $clientIp,
            ]);

            return false;
        }

        return true;
    }

    public function parsePayload(Request $request): WebhookPayload
    {
        $payload = json_decode($request->getContent(), true);

        if (! is_array($payload)) {
            throw new RuntimeException('Webhook payload must decode to an array.');
        }

        $repositorySlug = $this->extractRepositorySlug($payload);
        $branch = $this->extractBranch($payload);
        $actor = $this->extractActor($payload);

        return new WebhookPayload($repositorySlug, $branch, $actor, $payload);
    }

    public function getProviderName(): string
    {
        return 'bitbucket';
    }

    /**
     * @param  array<string, mixed>  $payload
     */
    private function extractRepositorySlug(array $payload): string
    {
        if (! array_key_exists('repository', $payload) || ! is_array($payload['repository'])) {
            throw new RuntimeException('Webhook payload must include a repository array.');
        }

        $repository = $payload['repository'];

        if (! array_key_exists('slug', $repository) || ! is_string($repository['slug'])) {
            throw new RuntimeException('Webhook payload must include repository.slug.');
        }

        $repositorySlug = trim($repository['slug']);

        if ($repositorySlug === '') {
            throw new RuntimeException('Webhook payload repository.slug must not be empty.');
        }

        return $repositorySlug;
    }

    /**
     * @param  array<string, mixed>  $payload
     */
    private function extractBranch(array $payload): string
    {
        if (! array_key_exists('push', $payload) || ! is_array($payload['push'])) {
            throw new RuntimeException('Webhook payload must include a push array.');
        }

        $push = $payload['push'];

        if (! array_key_exists('changes', $push) || ! is_array($push['changes'])) {
            throw new RuntimeException('Webhook payload must include push.changes.');
        }

        foreach ($push['changes'] as $change) {
            if (! is_array($change)) {
                continue;
            }

            if (! array_key_exists('new', $change) || ! is_array($change['new'])) {
                continue;
            }

            $newReference = $change['new'];

            if (! array_key_exists('name', $newReference) || ! is_string($newReference['name'])) {
                continue;
            }

            $branch = trim($newReference['name']);

            if ($branch !== '') {
                return $branch;
            }
        }

        throw new RuntimeException('Webhook payload must include at least one push change with a new branch name.');
    }

    /**
     * @param  array<string, mixed>  $payload
     */
    private function extractActor(array $payload): string
    {
        if (! array_key_exists('actor', $payload) || ! is_array($payload['actor'])) {
            throw new RuntimeException('Webhook payload must include an actor array.');
        }

        $actor = $payload['actor'];

        if (array_key_exists('display_name', $actor) && is_string($actor['display_name'])) {
            $displayName = trim($actor['display_name']);

            if ($displayName !== '') {
                return $displayName;
            }
        }

        if (array_key_exists('nickname', $actor) && is_string($actor['nickname'])) {
            $nickname = trim($actor['nickname']);

            if ($nickname !== '') {
                Log::info('Bitbucket webhook payload actor.display_name was missing, using actor.nickname instead.', [
                    'provider' => $this->getProviderName(),
                    'nickname' => $nickname,
                ]);

                return $nickname;
            }
        }

        if (array_key_exists('username', $actor) && is_string($actor['username'])) {
            $username = trim($actor['username']);

            if ($username !== '') {
                Log::info('Bitbucket webhook payload actor.display_name was missing, using actor.username instead.', [
                    'provider' => $this->getProviderName(),
                    'username' => $username,
                ]);

                return $username;
            }
        }

        throw new RuntimeException('Webhook payload actor must include display_name, nickname, or username.');
    }
}