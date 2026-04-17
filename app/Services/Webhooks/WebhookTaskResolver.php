<?php

namespace App\Services\Webhooks;

use App\DataTransferObjects\WebhookPayload;
use App\Models\Task;
use Illuminate\Support\Facades\Log;
use RuntimeException;

class WebhookTaskResolver
{
    public function resolve(WebhookPayload $payload): Task
    {
        $taskRegistry = config('webhooks.task_registry');

        if (! is_array($taskRegistry)) {
            throw new RuntimeException('Webhook task registry must be configured as an array.');
        }

        foreach ($taskRegistry as $index => $taskDefinition) {
            if (! is_array($taskDefinition)) {
                Log::warning('Skipping webhook task registry entry because it is not an array.', [
                    'index' => $index,
                ]);

                continue;
            }

            if (! $this->matchesRepository($taskDefinition, $payload->repositorySlug, $index)) {
                continue;
            }

            if (! $this->matchesBranch($taskDefinition, $payload->branch, $index)) {
                continue;
            }

            $taskName = $this->extractTaskName($taskDefinition, $index);
            $task = Task::query()->where('name', $taskName)->where('active', true)->first();

            if (! $task instanceof Task) {
                throw new RuntimeException('Webhook task registry matched a task name that does not exist in the database.');
            }

            Log::info('Resolved webhook payload to a deployment task.', [
                'repository' => $payload->repositorySlug,
                'branch' => $payload->branch,
                'task_name' => $task->name,
                'task_id' => $task->id,
            ]);

            return $task;
        }

        throw new RuntimeException('No webhook task matched the repository and branch.');
    }

    /**
     * @param  array<string, mixed>  $taskDefinition
     */
    private function matchesRepository(array $taskDefinition, string $repositorySlug, int|string $index): bool
    {
        if (! array_key_exists('repository', $taskDefinition) || ! is_string($taskDefinition['repository'])) {
            Log::warning('Skipping webhook task registry entry because repository is missing.', [
                'index' => $index,
            ]);

            return false;
        }

        return fnmatch($taskDefinition['repository'], $repositorySlug);
    }

    /**
     * @param  array<string, mixed>  $taskDefinition
     */
    private function matchesBranch(array $taskDefinition, string $branch, int|string $index): bool
    {
        if (! array_key_exists('branch', $taskDefinition) || ! is_string($taskDefinition['branch'])) {
            Log::warning('Skipping webhook task registry entry because branch is missing.', [
                'index' => $index,
            ]);

            return false;
        }

        return fnmatch($taskDefinition['branch'], $branch);
    }

    /**
     * @param  array<string, mixed>  $taskDefinition
     */
    private function extractTaskName(array $taskDefinition, int|string $index): string
    {
        if (! array_key_exists('task', $taskDefinition) || ! is_string($taskDefinition['task'])) {
            throw new RuntimeException('Webhook task registry entry must include a task name.');
        }

        $taskName = trim($taskDefinition['task']);

        if ($taskName === '') {
            throw new RuntimeException('Webhook task registry entry task name must not be empty.');
        }

        Log::info('Webhook task registry entry matched repository and branch.', [
            'index' => $index,
            'task_name' => $taskName,
        ]);

        return $taskName;
    }
}