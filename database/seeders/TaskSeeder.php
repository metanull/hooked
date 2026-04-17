<?php

namespace Database\Seeders;

use App\Models\Task;
use Illuminate\Database\Seeder;
use RuntimeException;

class TaskSeeder extends Seeder
{
    public function run(): void
    {
        $taskDefinitions = config('tasks');

        if (! is_array($taskDefinitions)) {
            throw new RuntimeException('Task configuration must be an array.');
        }

        foreach ($taskDefinitions as $name => $taskDefinition) {
            if (! is_string($name) || $name === '') {
                throw new RuntimeException('Task configuration keys must be non-empty strings.');
            }

            if (! is_array($taskDefinition)) {
                throw new RuntimeException('Each task definition must be an array.');
            }

            $directory = $this->requireString($taskDefinition, 'directory', $name);
            $scheduledTaskPath = $this->requireString($taskDefinition, 'scheduled_task_path', $name);
            $type = $this->requireString($taskDefinition, 'type', $name);
            $active = true;

            if (array_key_exists('active', $taskDefinition)) {
                $active = (bool) $taskDefinition['active'];
            }

            $webhookRepositoryPattern = null;
            $webhookBranchPattern = null;

            if (array_key_exists('webhook_match', $taskDefinition) && $taskDefinition['webhook_match'] !== null) {
                if (! is_array($taskDefinition['webhook_match'])) {
                    throw new RuntimeException('Task webhook_match must be an array or null.');
                }

                $webhookRepositoryPattern = $this->requireString($taskDefinition['webhook_match'], 'repository', $name);
                $webhookBranchPattern = $this->requireString($taskDefinition['webhook_match'], 'branch', $name);
            }

            Task::query()->updateOrCreate(
                ['name' => $name],
                [
                    'directory' => $directory,
                    'scheduled_task_path' => $scheduledTaskPath,
                    'type' => $type,
                    'active' => $active,
                    'webhook_repository_pattern' => $webhookRepositoryPattern,
                    'webhook_branch_pattern' => $webhookBranchPattern,
                ],
            );
        }
    }

    /**
     * @param  array<string, mixed>  $definition
     */
    private function requireString(array $definition, string $key, string $taskName): string
    {
        if (! array_key_exists($key, $definition) || ! is_string($definition[$key])) {
            throw new RuntimeException('Task '.$taskName.' is missing the required '.$key.' string.');
        }

        $value = trim($definition[$key]);

        if ($value === '') {
            throw new RuntimeException('Task '.$taskName.' has an empty '.$key.' value.');
        }

        return $value;
    }
}