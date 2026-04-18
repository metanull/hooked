<?php

namespace Tests\Feature;

use App\Livewire\DeploymentHistoryViewer;
use App\Models\Deployment;
use App\Models\Task;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Livewire\Livewire;
use Tests\TestCase;

class DeploymentHistoryViewerTest extends TestCase
{
    use RefreshDatabase;

    public function test_component_renders_deployments_and_can_expand_output(): void
    {
        $task = Task::query()->create([
            'name' => 'deploy-hooked',
            'directory' => 'upgrade',
            'label' => 'Hooked Deploy',
            'scheduled_task_path' => '\\upgrade.museumwnf.org\\hooked-deploy',
            'type' => 'run',
            'active' => true,
        ]);
        $deployment = Deployment::query()->create([
            'task_id' => $task->id,
            'triggered_by' => 'operator@example.test',
            'status' => 'completed',
            'started_at' => now()->subMinutes(5),
            'completed_at' => now(),
            'output' => "STDOUT:\nCompleted",
        ]);

        Livewire::test(DeploymentHistoryViewer::class)
            ->assertSee('Hooked Deploy')
            ->assertSee('operator@example.test')
            ->assertSee('completed')
            ->assertSee('5m 0s')
            ->call('toggleOutput', $deployment->id)
            ->assertSee('STDOUT:')
            ->assertSee('Completed');
    }

    public function test_component_filters_by_task_status_and_date_range(): void
    {
        $matchingTask = Task::query()->create([
            'name' => 'deploy-hooked',
            'directory' => 'upgrade',
            'label' => 'Hooked Deploy',
            'scheduled_task_path' => '\\upgrade.museumwnf.org\\hooked-deploy',
            'type' => 'run',
            'active' => true,
        ]);
        $otherTask = Task::query()->create([
            'name' => 'deploy-client',
            'directory' => 'upgrade',
            'label' => 'Client Deploy',
            'scheduled_task_path' => '\\upgrade.museumwnf.org\\client-deploy',
            'type' => 'run',
            'active' => true,
        ]);

        Deployment::query()->create([
            'task_id' => $matchingTask->id,
            'triggered_by' => 'recent@example.test',
            'status' => 'completed',
            'started_at' => now()->subDay(),
            'completed_at' => now()->subDay()->addMinutes(3),
            'output' => 'recent run',
        ]);
        Deployment::query()->create([
            'task_id' => $otherTask->id,
            'triggered_by' => 'older@example.test',
            'status' => 'failed',
            'started_at' => now()->subDays(10),
            'completed_at' => now()->subDays(10)->addMinutes(2),
            'output' => 'older run',
        ]);

        Livewire::test(DeploymentHistoryViewer::class)
            ->set('taskFilter', (string) $matchingTask->id)
            ->set('statusFilter', 'completed')
            ->set('dateFrom', now()->subDays(2)->format('Y-m-d'))
            ->set('dateTo', now()->format('Y-m-d'))
            ->assertSee('recent@example.test')
            ->assertDontSee('older@example.test');
    }

    public function test_component_sorts_rows_by_selected_column(): void
    {
        $taskA = Task::query()->create([
            'name' => 'deploy-a',
            'directory' => 'upgrade',
            'label' => 'A Deploy',
            'scheduled_task_path' => '\\upgrade.museumwnf.org\\deploy-a',
            'type' => 'run',
            'active' => true,
        ]);
        $taskB = Task::query()->create([
            'name' => 'deploy-b',
            'directory' => 'upgrade',
            'label' => 'B Deploy',
            'scheduled_task_path' => '\\upgrade.museumwnf.org\\deploy-b',
            'type' => 'run',
            'active' => true,
        ]);

        Deployment::query()->create([
            'task_id' => $taskB->id,
            'triggered_by' => 'zeta@example.test',
            'status' => 'completed',
            'started_at' => now()->subMinutes(2),
            'completed_at' => now()->subMinute(),
            'output' => 'zeta',
        ]);
        Deployment::query()->create([
            'task_id' => $taskA->id,
            'triggered_by' => 'alpha@example.test',
            'status' => 'completed',
            'started_at' => now()->subMinutes(6),
            'completed_at' => now()->subMinutes(5),
            'output' => 'alpha',
        ]);

        Livewire::test(DeploymentHistoryViewer::class)
            ->call('sortBy', 'triggered_by')
            ->assertSeeInOrder(['alpha@example.test', 'zeta@example.test'])
            ->call('sortBy', 'task_name')
            ->assertSeeInOrder(['A Deploy', 'B Deploy']);
    }
}