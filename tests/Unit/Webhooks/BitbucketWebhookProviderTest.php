<?php

namespace Tests\Unit\Webhooks;

use App\Contracts\TrustedWebhookIpRangeProviderInterface;
use App\Services\Webhooks\BitbucketWebhookProvider;
use Illuminate\Http\Request;
use RuntimeException;
use Tests\TestCase;

class BitbucketWebhookProviderTest extends TestCase
{
    public function test_validate_request_accepts_a_trusted_bitbucket_webhook_with_a_valid_signature(): void
    {
        $payload = [
            'repository' => ['slug' => 'hooked'],
            'push' => [
                'changes' => [
                    ['new' => ['name' => 'main']],
                ],
            ],
            'actor' => ['display_name' => 'Meta Null'],
        ];
        $content = json_encode($payload, JSON_THROW_ON_ERROR);
        $signature = hash_hmac('sha256', $content, 'shared-secret');
        $provider = new BitbucketWebhookProvider($this->createTrustedRangeProvider(['104.192.136.0/21']), 'Bitbucket-Webhooks/2.0', 'shared-secret');
        $request = Request::create('/webhook/bitbucket', 'POST', server: [
            'REMOTE_ADDR' => '104.192.140.10',
            'HTTP_USER_AGENT' => 'Bitbucket-Webhooks/2.0',
            'HTTP_X_HUB_SIGNATURE' => 'sha256='.$signature,
            'CONTENT_TYPE' => 'application/json',
        ], content: $content);

        $this->assertTrue($provider->validateRequest($request));
    }

    public function test_validate_request_rejects_an_untrusted_client_ip(): void
    {
        $provider = new BitbucketWebhookProvider($this->createTrustedRangeProvider(['104.192.136.0/21']));
        $request = Request::create('/webhook/bitbucket', 'POST', server: [
            'REMOTE_ADDR' => '192.168.10.5',
            'HTTP_USER_AGENT' => 'Bitbucket-Webhooks/2.0',
        ], content: '{"repository":{"slug":"hooked"}}');

        $this->assertFalse($provider->validateRequest($request));
    }

    public function test_validate_request_rejects_an_invalid_user_agent(): void
    {
        $provider = new BitbucketWebhookProvider($this->createTrustedRangeProvider(['104.192.136.0/21']));
        $request = Request::create('/webhook/bitbucket', 'POST', server: [
            'REMOTE_ADDR' => '104.192.140.10',
            'HTTP_USER_AGENT' => 'curl/8.7.1',
        ], content: '{"repository":{"slug":"hooked"}}');

        $this->assertFalse($provider->validateRequest($request));
    }

    public function test_parse_payload_extracts_the_repository_branch_and_actor(): void
    {
        $provider = new BitbucketWebhookProvider($this->createTrustedRangeProvider(['104.192.136.0/21']));
        $payload = [
            'repository' => ['slug' => 'hooked'],
            'push' => [
                'changes' => [
                    ['new' => ['name' => 'develop']],
                ],
            ],
            'actor' => ['display_name' => 'Deploy Bot'],
        ];
        $request = Request::create('/webhook/bitbucket', 'POST', content: json_encode($payload, JSON_THROW_ON_ERROR));

        $webhookPayload = $provider->parsePayload($request);

        $this->assertSame('hooked', $webhookPayload->repositorySlug);
        $this->assertSame('develop', $webhookPayload->branch);
        $this->assertSame('Deploy Bot', $webhookPayload->actor);
    }

    public function test_parse_payload_requires_a_branch_name_in_the_push_changes(): void
    {
        $provider = new BitbucketWebhookProvider($this->createTrustedRangeProvider(['104.192.136.0/21']));
        $payload = [
            'repository' => ['slug' => 'hooked'],
            'push' => [
                'changes' => [
                    ['new' => []],
                ],
            ],
            'actor' => ['display_name' => 'Deploy Bot'],
        ];
        $request = Request::create('/webhook/bitbucket', 'POST', content: json_encode($payload, JSON_THROW_ON_ERROR));

        $this->expectException(RuntimeException::class);
        $this->expectExceptionMessage('Webhook payload must include at least one push change with a new branch name.');

        $provider->parsePayload($request);
    }

    private function createTrustedRangeProvider(array $ranges): TrustedWebhookIpRangeProviderInterface
    {
        return new class ($ranges) implements TrustedWebhookIpRangeProviderInterface {
            /**
             * @param  array<int, string>  $ranges
             */
            public function __construct(
                private readonly array $ranges,
            ) {}

            public function getRanges(): array
            {
                return $this->ranges;
            }
        };
    }
}