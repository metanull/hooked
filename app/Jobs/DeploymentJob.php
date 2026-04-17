<?php

namespace App\Jobs;

use App\Models\Task;
use App\Services\PowerShellService;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;
use Illuminate\Support\Facades\Log;
use RuntimeException;

class DeploymentJob implements ShouldQueue
{
    use Queueable;

    public function __construct(
        public readonly int $taskId,
    ) {}

    public function handle(PowerShellService $powerShellService): void
    {
        $task = Task::query()->find($this->taskId);

        if (! $task instanceof Task) {
            throw new RuntimeException('Deployment job task could not be found.');
        }

        Log::info('Dispatching scheduled task from deployment job.', [
            'task_id' => $task->id,
            'task_name' => $task->name,
            'scheduled_task_path' => $task->scheduled_task_path,
        ]);

        $powerShellService->startScheduledTask($task->scheduled_task_path);
    }
}