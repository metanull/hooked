<?php

namespace App\Livewire;

use App\Models\Task;
use Illuminate\Contracts\View\View;
use Illuminate\Support\Collection;
use Livewire\Component;

class TaskDashboard extends Component
{
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
        if (! $task->active) {
            return 'Inactive';
        }

        return 'Status pending';
    }
}