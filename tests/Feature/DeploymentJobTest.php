<?php

namespace Tests\Feature;

use App\Jobs\DeploymentJob;
use App\Models\Deployment;
use App\Models\Task;
use App\Services\PowerShellService;
use App\Services\ProcessResult;
use Illuminate\Foundation\Testing\RefreshDatabase;
use RuntimeException;
use Tests\TestCase;

class DeploymentJobTest extends TestCase
{
    use RefreshDatabase;

    public function test_dispatch_sync_creates_a_completed_deployment_record(): void
    {
        $task = Task::query()->create([
            'name' => 'deploy-hooked',
            'directory' => 'upgrade',
            'scheduled_task_path' => '\\upgrade.museumwnf.org\\hooked-deploy',
            'type' => 'run',
            'active' => true,
        ]);
        $this->app->instance(PowerShellService::class, new class ('powershell', null, 'env', 'config/site/powershell.php', false) extends PowerShellService {
            public function startScheduledTask(string $taskPath): ProcessResult
            {
                return new ProcessResult(0, 'started', '');
            }
        });

        DeploymentJob::dispatchSync($task->id, 'Deploy Bot');

        $deployment = Deployment::query()->first();

        $this->assertInstanceOf(Deployment::class, $deployment);
        $this->assertSame($task->id, $deployment->task_id);
        $this->assertSame('Deploy Bot', $deployment->triggered_by);
        $this->assertSame('completed', $deployment->status);
        $this->assertNotNull($deployment->started_at);
        $this->assertNotNull($deployment->completed_at);
        $this->assertStringContainsString('Exit code: 0', $deployment->output ?? '');
        $this->assertStringContainsString('started', $deployment->output ?? '');

        $this->assertDatabaseHas('audit_log', [
            'user' => null,
            'action' => 'task.triggered',
            'target' => 'deploy-hooked',
        ]);
    }

    public function test_dispatch_sync_marks_the_deployment_as_failed_when_powershell_fails(): void
    {
        $task = Task::query()->create([
            'name' => 'deploy-hooked',
            'directory' => 'upgrade',
            'scheduled_task_path' => '\\upgrade.museumwnf.org\\hooked-deploy',
            'type' => 'run',
            'active' => true,
        ]);
        $this->app->instance(PowerShellService::class, new class ('powershell', null, 'env', 'config/site/powershell.php', false) extends PowerShellService {
            public function startScheduledTask(string $taskPath): ProcessResult
            {
                return new ProcessResult(1, '', 'task failed');
            }
        });

        $this->expectException(RuntimeException::class);
        $this->expectExceptionMessage('Scheduled task execution failed.');

        try {
            DeploymentJob::dispatchSync($task->id, 'Deploy Bot');
        } finally {
            $deployment = Deployment::query()->first();

            $this->assertInstanceOf(Deployment::class, $deployment);
            $this->assertSame('failed', $deployment->status);
            $this->assertNotNull($deployment->completed_at);
            $this->assertStringContainsString('Exit code: 1', $deployment->output ?? '');
            $this->assertStringContainsString('task failed', $deployment->output ?? '');
        }
    }
}