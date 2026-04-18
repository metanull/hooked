<?php

namespace App\Services\Tasks;

use App\Models\Deployment;
use App\Models\Task;
use App\Services\PowerShellService;
use Illuminate\Support\Facades\Log;
use RuntimeException;

class TaskExecutionService
{
    public function __construct(
        private readonly PowerShellService $powerShellService,
    ) {}

    public function trigger(Task $task, string $triggeredBy): Deployment
    {
        $startedAt = now();
        $result = $this->powerShellService->startScheduledTask($task->scheduled_task_path);
        $status = 'queued';

        if (! $result->successful()) {
            $status = 'failed';
        }

        $deployment = $task->deployments()->create([
            'triggered_by' => $triggeredBy,
            'status' => $status,
            'started_at' => $startedAt,
            'completed_at' => now(),
            'output' => trim($result->stdout.PHP_EOL.$result->stderr),
        ]);

        if ($result->successful()) {
            Log::info('Triggered scheduled task from the task dashboard.', [
                'task_id' => $task->id,
                'task_name' => $task->name,
                'deployment_id' => $deployment->id,
                'triggered_by' => $triggeredBy,
            ]);

            return $deployment;
        }

        Log::error('Triggering a scheduled task from the task dashboard failed.', [
            'task_id' => $task->id,
            'task_name' => $task->name,
            'deployment_id' => $deployment->id,
            'triggered_by' => $triggeredBy,
            'exit_code' => $result->exitCode,
            'stdout' => $result->stdout,
            'stderr' => $result->stderr,
        ]);

        throw new RuntimeException('Unable to trigger the scheduled task.');
    }
}