<?php

namespace Tests\Feature;

use App\Livewire\TaskDashboard;
use App\Models\Deployment;
use App\Models\Task;
use App\Models\User;
use App\Services\Tasks\TaskExecutionService;
use App\Services\Tasks\TaskStatusService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Livewire\Livewire;
use Tests\TestCase;

class TaskDashboardTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->app->instance(TaskStatusService::class, new class extends TaskStatusService {
            public function __construct()
            {
            }

            public function read(Task $task): array
            {
                return [
                    'badge_text' => '2 commits',
                    'detail' => 'Last run 2 hours ago with Task Scheduler result 0.',
                    'commit_count' => 2,
                    'last_run_at' => null,
                    'last_task_result' => 0,
                ];
            }
        });
    }

    public function test_dashboard_page_requires_authentication(): void
    {
        $this->get('/admin/dashboard')->assertRedirect('/login');
    }

    public function test_task_dashboard_groups_tasks_by_directory_and_renders_labels(): void
    {
        Task::query()->create([
            'name' => 'books_client',
            'directory' => 'books',
            'label' => 'client',
            'scheduled_task_path' => '\\www.museumwnf.org\\books-client',
            'type' => 'run',
            'active' => true,
        ]);
        Task::query()->create([
            'name' => 'books_api',
            'directory' => 'books',
            'label' => 'api',
            'scheduled_task_path' => '\\www.museumwnf.org\\books-api',
            'type' => 'run',
            'active' => true,
        ]);
        Task::query()->create([
            'name' => 'local_webhook',
            'directory' => 'local',
            'label' => 'webhook',
            'scheduled_task_path' => '\\local.museumwnf.org\\webhook',
            'type' => 'run',
            'active' => true,
        ]);

        Livewire::test(TaskDashboard::class)
            ->assertSee('Books')
            ->assertSee('Local')
            ->assertSee('client')
            ->assertSee('api')
            ->assertSee('webhook')
            ->assertSee('2 commits');
    }

    public function test_task_dashboard_uses_expected_tones_for_client_api_and_other_tasks(): void
    {
        $dashboard = new TaskDashboard();

        $clientTask = new Task(['label' => 'client']);
        $apiTask = new Task(['label' => 'portal-api']);
        $otherTask = new Task(['label' => 'webhook']);

        $this->assertSame('green', $dashboard->badgeTone($clientTask));
        $this->assertSame('amber', $dashboard->badgeTone($apiTask));
        $this->assertSame('slate', $dashboard->badgeTone($otherTask));
    }

    public function test_authenticated_user_can_open_the_task_dashboard(): void
    {
        $user = User::factory()->create();

        $this->actingAs($user)
            ->get('/admin/dashboard')
            ->assertOk()
            ->assertSeeLivewire('task-dashboard');
    }

    public function test_trigger_task_creates_a_deployment_record(): void
    {
        $task = Task::query()->create([
            'name' => 'books_client',
            'directory' => 'books',
            'label' => 'client',
            'scheduled_task_path' => '\\www.museumwnf.org\\books-client',
            'type' => 'run',
            'active' => true,
        ]);
        $user = User::factory()->create();
        $this->actingAs($user);
        $this->app->instance(TaskExecutionService::class, new class extends TaskExecutionService {
            public function __construct()
            {
            }

            public function trigger(Task $task, string $triggeredBy): Deployment
            {
                return $task->deployments()->create([
                    'triggered_by' => $triggeredBy,
                    'status' => 'queued',
                    'started_at' => now(),
                    'completed_at' => now(),
                    'output' => 'Triggered',
                ]);
            }
        });

        Livewire::actingAs($user)
            ->test(TaskDashboard::class)
            ->call('triggerTask', $task->id);

        $this->assertDatabaseHas('deployments', [
            'task_id' => $task->id,
            'triggered_by' => $user->email,
            'status' => 'queued',
        ]);
    }
}