<?php

namespace Tests\Feature;

use App\Models\Task;
use Database\Seeders\TaskSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class TaskSeederTest extends TestCase
{
    use RefreshDatabase;

    public function test_task_seeder_populates_the_task_registry_from_configuration(): void
    {
        $this->seed(TaskSeeder::class);

        $webhookTask = Task::query()->where('name', 'local_webhook')->first();
        $manualTask = Task::query()->where('name', 'data_add-uploaded-images')->first();

        $this->assertInstanceOf(Task::class, $webhookTask);
        $this->assertSame('local.museumwnf.org', $webhookTask->directory);
        $this->assertSame('run', $webhookTask->type);
        $this->assertSame('hooked', $webhookTask->webhook_repository_pattern);
        $this->assertSame('main', $webhookTask->webhook_branch_pattern);

        $this->assertInstanceOf(Task::class, $manualTask);
        $this->assertSame('local.museumwnf.org', $manualTask->directory);
        $this->assertNull($manualTask->webhook_repository_pattern);
        $this->assertNull($manualTask->webhook_branch_pattern);
    }
}