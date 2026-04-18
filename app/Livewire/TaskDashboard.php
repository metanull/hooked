<?php

namespace App\Livewire;

use App\Models\Deployment;
use App\Models\Task;
use App\Services\AuditLogger;
use App\Services\Tasks\TaskExecutionService;
use App\Services\Tasks\TaskStatusService;
use Illuminate\Contracts\View\View;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Log;
use Livewire\Component;

class TaskDashboard extends Component
{
    /**
     * @var array<int, array{badge_text: string, detail: string}>
     */
    public array $taskStatuses = [];

    /**
     * @var array<int, string>
     */
    public array $expandedDirectories = [];

    public function mount(TaskStatusService $taskStatusService): void
    {
        $this->loadStatuses($taskStatusService);

        $firstDirectory = Task::query()
            ->where('active', true)
            ->orderBy('directory')
            ->value('directory');

        if (is_string($firstDirectory) && $firstDirectory !== '') {
            $this->expandedDirectories = [$firstDirectory];
        }
    }

    public function render(): View
    {
        $tasks = Task::query()
            ->where('active', true)
            ->orderBy('directory')
            ->orderBy('label')
            ->get();

        return view('livewire.task-dashboard', [
            'groupedTasks' => $tasks->groupBy('directory'),
        ]);
    }

    public function triggerTask(int $taskId, TaskExecutionService $taskExecutionService, TaskStatusService $taskStatusService, AuditLogger $auditLogger): void
    {
        $task = $this->findTask($taskId);
        $user = Auth::user();

        if ($user === null) {
            abort(403);
        }

        $deployment = $taskExecutionService->trigger($task, $user->email);
        $auditLogger->log('task.triggered', $task->name, [
            'triggered_by' => $user->email,
            'deployment_id' => $deployment->id,
            'source' => 'task_dashboard',
        ]);
        $this->loadStatuses($taskStatusService);

        session()->flash('status', 'Triggered task '.$task->label.' with deployment record #'.$deployment->id.'.');
    }

    public function refreshStatuses(TaskStatusService $taskStatusService): void
    {
        $this->loadStatuses($taskStatusService);
    }

    public function toggleDirectory(string $directory, TaskStatusService $taskStatusService): void
    {
        if (in_array($directory, $this->expandedDirectories, true)) {
            $this->expandedDirectories = array_values(array_filter(
                $this->expandedDirectories,
                fn (string $expandedDirectory): bool => $expandedDirectory !== $directory,
            ));

            return;
        }

        $this->expandedDirectories[] = $directory;
        $this->refreshDirectoryStatus($directory, $taskStatusService);
    }

    public function refreshDirectoryStatus(string $directory, TaskStatusService $taskStatusService): void
    {
        foreach (Task::query()->where('active', true)->where('directory', $directory)->get() as $task) {
            try {
                $this->taskStatuses[$task->id] = $taskStatusService->read($task);
            } catch (\Throwable $throwable) {
                Log::error('Task dashboard directory status refresh failed for an individual task.', [
                    'task_id' => $task->id,
                    'task_name' => $task->name,
                    'message' => $throwable->getMessage(),
                ]);

                $this->taskStatuses[$task->id] = [
                    'badge_text' => 'Status error',
                    'detail' => $throwable->getMessage(),
                ];
            }
        }
    }

    public function badgeTone(Task $task): string
    {
        if (str_ends_with($task->label, 'client')) {
            return 'green';
        }

        if (str_ends_with($task->label, 'api')) {
            return 'amber';
        }

        return 'slate';
    }

    public function statusText(Task $task): string
    {
        if (array_key_exists($task->id, $this->taskStatuses) && array_key_exists('badge_text', $this->taskStatuses[$task->id])) {
            return $this->taskStatuses[$task->id]['badge_text'];
        }

        return 'Unavailable';
    }

    public function statusDetail(Task $task): string
    {
        if (array_key_exists($task->id, $this->taskStatuses) && array_key_exists('detail', $this->taskStatuses[$task->id])) {
            return $this->taskStatuses[$task->id]['detail'];
        }

        return 'No task status has been loaded.';
    }

    private function findTask(int $taskId): Task
    {
        $task = Task::query()->find($taskId);

        if (! $task instanceof Task) {
            abort(404);
        }

        return $task;
    }

    private function loadStatuses(TaskStatusService $taskStatusService): void
    {
        $this->taskStatuses = [];

        foreach (Task::query()->where('active', true)->get() as $task) {
            $this->refreshDirectoryStatus($task->directory, $taskStatusService);
        }
    }
}