<?php

namespace App\Livewire;

use App\Models\Deployment;
use App\Models\Task;
use Illuminate\Contracts\View\View;
use Illuminate\Database\Eloquent\Builder;
use Livewire\Component;

class DeploymentHistoryViewer extends Component
{
    public string $taskFilter = '';

    public string $statusFilter = '';

    public string $dateFrom = '';

    public string $dateTo = '';

    public string $sortColumn = 'started_at';

    public string $sortDirection = 'desc';

    /**
     * @var array<int, int>
     */
    public array $expandedDeployments = [];

    public function render(): View
    {
        $query = Deployment::query()->with('task');

        if ($this->taskFilter !== '') {
            $query->where('task_id', (int) $this->taskFilter);
        }

        if ($this->statusFilter !== '') {
            $query->where('status', $this->statusFilter);
        }

        if ($this->dateFrom !== '') {
            $query->whereDate('started_at', '>=', $this->dateFrom);
        }

        if ($this->dateTo !== '') {
            $query->whereDate('started_at', '<=', $this->dateTo);
        }

        $this->applySorting($query);

        return view('livewire.deployment-history-viewer', [
            'deployments' => $query->get(),
            'tasks' => Task::query()->orderBy('label')->orderBy('name')->get(),
            'availableStatuses' => Deployment::query()->distinct()->orderBy('status')->pluck('status'),
        ]);
    }

    public function sortBy(string $column): void
    {
        if (! in_array($column, $this->sortableColumns(), true)) {
            return;
        }

        if ($this->sortColumn === $column) {
            $this->sortDirection = $this->sortDirection === 'asc' ? 'desc' : 'asc';

            return;
        }

        $this->sortColumn = $column;
        $this->sortDirection = $column === 'started_at' ? 'desc' : 'asc';
    }

    public function toggleOutput(int $deploymentId): void
    {
        if (in_array($deploymentId, $this->expandedDeployments, true)) {
            $this->expandedDeployments = array_values(array_filter(
                $this->expandedDeployments,
                fn (int $expandedDeploymentId): bool => $expandedDeploymentId !== $deploymentId,
            ));

            return;
        }

        $this->expandedDeployments[] = $deploymentId;
    }

    public function isExpanded(int $deploymentId): bool
    {
        return in_array($deploymentId, $this->expandedDeployments, true);
    }

    public function durationText(Deployment $deployment): string
    {
        if ($deployment->started_at === null || $deployment->completed_at === null) {
            return 'Not available';
        }

        $durationSeconds = $deployment->started_at->diffInSeconds($deployment->completed_at, true);
        $minutes = intdiv($durationSeconds, 60);
        $seconds = $durationSeconds % 60;

        if ($minutes === 0) {
            return $seconds.'s';
        }

        return $minutes.'m '.$seconds.'s';
    }

    public function sortIndicator(string $column): string
    {
        if ($this->sortColumn !== $column) {
            return '';
        }

        return $this->sortDirection === 'asc' ? '↑' : '↓';
    }

    /**
     * @param  Builder<Deployment>  $query
     */
    private function applySorting(Builder $query): void
    {
        if ($this->sortColumn === 'task_name') {
            $query->orderBy(
                Task::query()
                    ->select('label')
                    ->whereColumn('tasks.id', 'deployments.task_id'),
                $this->sortDirection,
            );
            $query->orderBy('deployments.id', 'desc');

            return;
        }

        if ($this->sortColumn === 'duration_seconds') {
            $query->orderByRaw(
                "case when completed_at is null or started_at is null then null else cast(strftime('%s', completed_at) as integer) - cast(strftime('%s', started_at) as integer) end {$this->sortDirection}"
            );
            $query->orderBy('deployments.id', 'desc');

            return;
        }

        $query->orderBy($this->sortColumn, $this->sortDirection);
        $query->orderBy('deployments.id', 'desc');
    }

    /**
     * @return array<int, string>
     */
    private function sortableColumns(): array
    {
        return [
            'task_name',
            'triggered_by',
            'status',
            'started_at',
            'duration_seconds',
        ];
    }
}