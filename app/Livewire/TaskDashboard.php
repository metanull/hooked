<?php

namespace App\Livewire;

use App\Models\Deployment;
use App\Models\Task;
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

    public function mount(TaskStatusService $taskStatusService): void
    {
        $this->loadStatuses($taskStatusService);
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

    public function triggerTask(int $taskId, TaskExecutionService $taskExecutionService, TaskStatusService $taskStatusService): void
    {
        $task = $this->findTask($taskId);
        $user = Auth::user();

        if ($user === null) {
            abort(403);
        }

        $deployment = $taskExecutionService->trigger($task, $user->email);
        $this->loadStatuses($taskStatusService);

        session()->flash('status', 'Triggered task '.$task->label.' with deployment record #'.$deployment->id.'.');
    }

    public function refreshStatuses(TaskStatusService $taskStatusService): void
    {
        $this->loadStatuses($taskStatusService);
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
            try {
                $this->taskStatuses[$task->id] = $taskStatusService->read($task);
            } catch (\Throwable $throwable) {
                Log::error('Task dashboard status refresh failed for an individual task.', [
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
}