<?php

namespace App\Jobs;

use App\Models\Deployment;
use App\Models\Task;
use App\Services\PowerShellService;
use App\Services\ProcessResult;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;
use Illuminate\Support\Facades\Log;
use Throwable;
use RuntimeException;

class DeploymentJob implements ShouldQueue
{
    use Queueable;

    public int $tries = 3;

    public function __construct(
        public readonly int $taskId,
        public readonly ?string $triggeredBy = null,
    ) {}

    public function handle(PowerShellService $powerShellService): void
    {
        $task = Task::query()->find($this->taskId);

        if (! $task instanceof Task) {
            throw new RuntimeException('Deployment job task could not be found.');
        }

        $triggeredBy = $this->resolveTriggeredBy();
        $deployment = Deployment::query()->create([
            'task_id' => $task->id,
            'triggered_by' => $triggeredBy,
            'status' => 'running',
            'started_at' => now(),
        ]);

        Log::info('Dispatching scheduled task from deployment job.', [
            'task_id' => $task->id,
            'task_name' => $task->name,
            'scheduled_task_path' => $task->scheduled_task_path,
            'deployment_id' => $deployment->id,
            'triggered_by' => $triggeredBy,
        ]);

        try {
            $result = $powerShellService->startScheduledTask($task->scheduled_task_path);
            $output = $this->formatOutput($result);

            if (! $result->successful()) {
                $deployment->forceFill([
                    'status' => 'failed',
                    'completed_at' => now(),
                    'output' => $output,
                ])->save();

                Log::error('Deployment job failed to start the scheduled task.', [
                    'task_id' => $task->id,
                    'task_name' => $task->name,
                    'deployment_id' => $deployment->id,
                    'exit_code' => $result->exitCode,
                ]);

                throw new RuntimeException('Scheduled task execution failed.');
            }

            $deployment->forceFill([
                'status' => 'completed',
                'completed_at' => now(),
                'output' => $output,
            ])->save();
        } catch (Throwable $throwable) {
            if ($deployment->status !== 'failed') {
                $deployment->forceFill([
                    'status' => 'failed',
                    'completed_at' => now(),
                    'output' => $throwable->getMessage(),
                ])->save();
            }

            Log::error('Deployment job encountered an exception.', [
                'task_id' => $task->id,
                'task_name' => $task->name,
                'deployment_id' => $deployment->id,
                'message' => $throwable->getMessage(),
            ]);

            throw $throwable;
        }
    }

    private function resolveTriggeredBy(): string
    {
        if (is_string($this->triggeredBy) && trim($this->triggeredBy) !== '') {
            return trim($this->triggeredBy);
        }

        Log::info('Deployment job triggered_by was not provided. Using the explicit system:webhook actor label.', [
            'task_id' => $this->taskId,
        ]);

        return 'system:webhook';
    }

    private function formatOutput(ProcessResult $result): string
    {
        $outputLines = [
            'Exit code: '.$result->exitCode,
        ];

        if ($result->stdout !== '') {
            $outputLines[] = 'STDOUT:';
            $outputLines[] = $result->stdout;
        }

        if ($result->stderr !== '') {
            $outputLines[] = 'STDERR:';
            $outputLines[] = $result->stderr;
        }

        return implode(PHP_EOL, $outputLines);
    }
}