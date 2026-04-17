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
        $candidateTasks = Task::query()
            ->where('active', true)
            ->where('type', 'run')
            ->whereNotNull('webhook_repository_pattern')
            ->whereNotNull('webhook_branch_pattern')
            ->get();

        foreach ($candidateTasks as $task) {
            if (! is_string($task->webhook_repository_pattern) || ! fnmatch($task->webhook_repository_pattern, $payload->repositorySlug)) {
                continue;
            }

            if (! is_string($task->webhook_branch_pattern) || ! fnmatch($task->webhook_branch_pattern, $payload->branch)) {
                continue;
            }

            Log::info('Resolved webhook payload to a deployment task from the database task registry.', [
                'repository' => $payload->repositorySlug,
                'branch' => $payload->branch,
                'task_name' => $task->name,
                'task_id' => $task->id,
            ]);

            return $task;
        }

        throw new RuntimeException('No webhook task matched the repository and branch.');
    }
}