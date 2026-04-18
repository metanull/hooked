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
        $dxaTask = Task::query()->where('name', 'dxa_galleries-client')->first();

        $this->assertInstanceOf(Task::class, $webhookTask);
        $this->assertSame('local', $webhookTask->directory);
        $this->assertSame('webhook', $webhookTask->label);
        $this->assertSame('run', $webhookTask->type);
        $this->assertSame('hooked', $webhookTask->webhook_repository_pattern);
        $this->assertSame('main', $webhookTask->webhook_branch_pattern);

        $this->assertInstanceOf(Task::class, $manualTask);
        $this->assertSame('data', $manualTask->directory);
        $this->assertSame('add-uploaded-images', $manualTask->label);
        $this->assertNull($manualTask->webhook_repository_pattern);
        $this->assertNull($manualTask->webhook_branch_pattern);

        $this->assertInstanceOf(Task::class, $dxaTask);
        $this->assertSame('dxa', $dxaTask->directory);
        $this->assertSame('galleries-client', $dxaTask->label);

        $this->assertGreaterThan(80, Task::query()->count());
    }
}