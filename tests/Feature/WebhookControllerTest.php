<?php

namespace Tests\Feature;

use App\Contracts\TrustedWebhookIpRangeProviderInterface;
use App\Jobs\DeploymentJob;
use App\Models\Task;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Bus;
use Tests\TestCase;

class WebhookControllerTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        config()->set('ip_whitelist', [
            'source' => 'env',
            'site_path' => base_path('config/site/ip-whitelist.php'),
            'enabled' => true,
            'addresses' => '104.192.136.0/21',
        ]);

        $this->app->instance(TrustedWebhookIpRangeProviderInterface::class, new class implements TrustedWebhookIpRangeProviderInterface {
            public function getRanges(): array
            {
                return ['104.192.136.0/21'];
            }
        });
    }

    public function test_webhook_endpoint_accepts_a_valid_bitbucket_request_and_dispatches_a_job(): void
    {
        Bus::fake();
        $task = Task::query()->create([
            'name' => 'deploy-hooked',
            'directory' => 'upgrade',
            'scheduled_task_path' => '\\upgrade.museumwnf.org\\hooked-deploy',
            'type' => 'run',
            'active' => true,
            'webhook_repository_pattern' => 'hooked',
            'webhook_branch_pattern' => 'main',
        ]);
        $payload = [
            'repository' => ['slug' => 'hooked'],
            'push' => ['changes' => [['new' => ['name' => 'main']]]],
            'actor' => ['display_name' => 'Deploy Bot'],
        ];

        $response = $this
            ->withServerVariables([
                'REMOTE_ADDR' => '104.192.140.15',
                'HTTP_USER_AGENT' => 'Bitbucket-Webhooks/2.0',
            ])
            ->postJson('/webhook/bitbucket', $payload);

        $response
            ->assertOk()
            ->assertJson([
                'status' => 'accepted',
                'provider' => 'bitbucket',
                'task' => 'deploy-hooked',
            ]);

        Bus::assertDispatched(DeploymentJob::class, function (DeploymentJob $job) use ($task): bool {
            return $job->taskId === $task->id;
        });
    }

    public function test_webhook_endpoint_rejects_a_request_that_fails_provider_validation(): void
    {
        Bus::fake();

        $response = $this
            ->withServerVariables([
                'REMOTE_ADDR' => '104.192.140.15',
                'HTTP_USER_AGENT' => 'curl/8.7.1',
            ])
            ->postJson('/webhook/bitbucket', [
                'repository' => ['slug' => 'hooked'],
                'push' => ['changes' => [['new' => ['name' => 'main']]]],
                'actor' => ['display_name' => 'Deploy Bot'],
            ]);

        $response->assertForbidden();
        Bus::assertNothingDispatched();
    }

    public function test_webhook_endpoint_returns_a_bad_request_when_no_task_matches_the_payload(): void
    {
        Bus::fake();
        Task::query()->create([
            'name' => 'deploy-hooked',
            'directory' => 'upgrade',
            'scheduled_task_path' => '\\upgrade.museumwnf.org\\hooked-deploy',
            'type' => 'run',
            'active' => true,
            'webhook_repository_pattern' => 'other-repository',
            'webhook_branch_pattern' => 'develop',
        ]);

        $response = $this
            ->withServerVariables([
                'REMOTE_ADDR' => '104.192.140.15',
                'HTTP_USER_AGENT' => 'Bitbucket-Webhooks/2.0',
            ])
            ->postJson('/webhook/bitbucket', [
                'repository' => ['slug' => 'hooked'],
                'push' => ['changes' => [['new' => ['name' => 'main']]]],
                'actor' => ['display_name' => 'Deploy Bot'],
            ]);

        $response
            ->assertBadRequest()
            ->assertJson([
                'message' => 'No webhook task matched the repository and branch.',
            ]);

        Bus::assertNothingDispatched();
    }
}