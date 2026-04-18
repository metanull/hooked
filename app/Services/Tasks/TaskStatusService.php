<?php

namespace App\Services\Tasks;

use App\Models\Task;
use App\Services\PowerShellService;
use Carbon\CarbonImmutable;
use Illuminate\Support\Facades\Log;
use RuntimeException;

class TaskStatusService
{
    public function __construct(
        private readonly PowerShellService $powerShellService,
    ) {}

    /**
     * @return array{badge_text: string, detail: string, commit_count: ?int, last_run_at: ?CarbonImmutable, last_task_result: ?int}
     */
    public function read(Task $task): array
    {
        $definition = $this->definitionFor($task);
        $scheduledTaskInfo = $this->readScheduledTaskInfo($task);
        $commitCount = null;

        if (array_key_exists('repo_path', $definition) && is_string($definition['repo_path'])) {
            $repoBranch = 'master';

            if (array_key_exists('repo_branch', $definition) && is_string($definition['repo_branch']) && trim($definition['repo_branch']) !== '') {
                $repoBranch = trim($definition['repo_branch']);
            }

            $commitCount = $this->readCommitCount($task, $definition['repo_path'], $repoBranch);
        }

        $lastRunAt = null;

        if (array_key_exists('LastRunTime', $scheduledTaskInfo) && is_string($scheduledTaskInfo['LastRunTime']) && trim($scheduledTaskInfo['LastRunTime']) !== '') {
            $lastRunAt = CarbonImmutable::parse($scheduledTaskInfo['LastRunTime']);
        }

        $lastTaskResult = null;

        if (array_key_exists('LastTaskResult', $scheduledTaskInfo) && is_numeric($scheduledTaskInfo['LastTaskResult'])) {
            $lastTaskResult = (int) $scheduledTaskInfo['LastTaskResult'];
        }

        $badgeText = 'No run history';

        if ($commitCount !== null) {
            $badgeText = $commitCount.' commits';
        } elseif ($lastRunAt instanceof CarbonImmutable) {
            $badgeText = $lastRunAt->diffForHumans();
        }

        $detail = 'No Task Scheduler run information is available.';

        if ($lastTaskResult !== null && $lastRunAt instanceof CarbonImmutable) {
            $detail = 'Last run '.$lastRunAt->diffForHumans().' with Task Scheduler result '.$lastTaskResult.'.';
        } elseif ($lastTaskResult !== null) {
            $detail = 'Last Task Scheduler result '.$lastTaskResult.'.';
        } elseif ($lastRunAt instanceof CarbonImmutable) {
            $detail = 'Last run '.$lastRunAt->diffForHumans().'.';
        }

        return [
            'badge_text' => $badgeText,
            'detail' => $detail,
            'commit_count' => $commitCount,
            'last_run_at' => $lastRunAt,
            'last_task_result' => $lastTaskResult,
        ];
    }

    /**
     * @return array<string, mixed>
     */
    private function definitionFor(Task $task): array
    {
        $definitions = config('tasks');

        if (! is_array($definitions)) {
            throw new RuntimeException('Task configuration must be an array.');
        }

        if (! array_key_exists($task->name, $definitions) || ! is_array($definitions[$task->name])) {
            Log::error('Task dashboard status lookup failed because the task definition was missing from config.', [
                'task_name' => $task->name,
            ]);

            throw new RuntimeException('Task definition is missing from configuration.');
        }

        return $definitions[$task->name];
    }

    /**
     * @return array<string, mixed>
     */
    private function readScheduledTaskInfo(Task $task): array
    {
        [$taskPath, $taskName] = $this->normalizeScheduledTaskPath($task->scheduled_task_path);
        $command = "Get-ScheduledTaskInfo -TaskPath '".$this->escapeForPowerShellSingleQuotes($taskPath)."' -TaskName '".$this->escapeForPowerShellSingleQuotes($taskName)."' | ConvertTo-Json -Depth 5";
        $result = $this->powerShellService->run($command);

        if (! $result->successful()) {
            Log::error('Task dashboard status lookup failed while querying Task Scheduler.', [
                'task_name' => $task->name,
                'scheduled_task_path' => $task->scheduled_task_path,
                'exit_code' => $result->exitCode,
                'stdout' => $result->stdout,
                'stderr' => $result->stderr,
            ]);

            throw new RuntimeException('Unable to query Task Scheduler status.');
        }

        $decoded = json_decode(trim($result->stdout), true);

        if (! is_array($decoded)) {
            throw new RuntimeException('Task Scheduler status payload must decode to an array.');
        }

        return $decoded;
    }

    private function readCommitCount(Task $task, string $repoPath, string $repoBranch): int
    {
        $command = "Set-Location '".$this->escapeForPowerShellSingleQuotes($repoPath)."'; git fetch --quiet; git rev-list '".$this->escapeForPowerShellSingleQuotes($repoBranch)."'..'origin/".$this->escapeForPowerShellSingleQuotes($repoBranch)."' --count";
        $result = $this->powerShellService->run($command, 120);

        if (! $result->successful()) {
            Log::error('Task dashboard status lookup failed while querying git commit count.', [
                'task_name' => $task->name,
                'repo_path' => $repoPath,
                'repo_branch' => $repoBranch,
                'exit_code' => $result->exitCode,
                'stdout' => $result->stdout,
                'stderr' => $result->stderr,
            ]);

            throw new RuntimeException('Unable to query the git commit count for the task.');
        }

        $count = trim($result->stdout);

        if (! preg_match('/^\d+$/', $count)) {
            throw new RuntimeException('Git commit count output must be an integer.');
        }

        return (int) $count;
    }

    /**
     * @return array{0: string, 1: string}
     */
    private function normalizeScheduledTaskPath(string $taskPath): array
    {
        $normalizedTaskPath = str_replace('/', '\\', trim($taskPath));
        $trimmedTaskPath = rtrim($normalizedTaskPath, '\\');

        if ($trimmedTaskPath === '') {
            throw new RuntimeException('Scheduled task path must include a task name.');
        }

        $lastSeparatorPosition = strrpos($trimmedTaskPath, '\\');

        if ($lastSeparatorPosition === false) {
            return ['\\', $trimmedTaskPath];
        }

        $resolvedTaskName = substr($trimmedTaskPath, $lastSeparatorPosition + 1);
        $resolvedTaskPath = substr($trimmedTaskPath, 0, $lastSeparatorPosition + 1);

        if (! is_string($resolvedTaskName) || $resolvedTaskName === '') {
            throw new RuntimeException('Scheduled task path must include a task name.');
        }

        if (! is_string($resolvedTaskPath) || $resolvedTaskPath === '') {
            $resolvedTaskPath = '\\';
        }

        return [$resolvedTaskPath, $resolvedTaskName];
    }

    private function escapeForPowerShellSingleQuotes(string $value): string
    {
        return str_replace("'", "''", $value);
    }
}