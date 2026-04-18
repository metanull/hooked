<div class="rounded-xl border border-slate-200 bg-white p-6 shadow-sm">
    <div class="flex flex-col gap-6">
        <div>
            <p class="text-sm font-semibold uppercase tracking-[0.2em] text-slate-500">Deployment History</p>
            <h3 class="mt-2 text-2xl font-semibold text-slate-900">Recent deployment executions</h3>
            <p class="mt-2 max-w-3xl text-sm text-slate-600">
                Review task runs, filter by task or date, and expand individual rows to inspect the captured stdout and stderr output.
            </p>
        </div>

        <div class="grid gap-4 rounded-xl border border-slate-200 bg-slate-50 p-4 md:grid-cols-2 xl:grid-cols-4">
            <label class="space-y-2 text-sm text-slate-700">
                <span class="font-semibold text-slate-900">Task</span>
                <select wire:model.live="taskFilter" class="w-full rounded-lg border-slate-300 text-sm shadow-sm focus:border-slate-500 focus:ring-slate-500">
                    <option value="">All tasks</option>
                    @foreach ($tasks as $task)
                        <option value="{{ $task->id }}">{{ $task->label }} ({{ $task->name }})</option>
                    @endforeach
                </select>
            </label>

            <label class="space-y-2 text-sm text-slate-700">
                <span class="font-semibold text-slate-900">Status</span>
                <select wire:model.live="statusFilter" class="w-full rounded-lg border-slate-300 text-sm shadow-sm focus:border-slate-500 focus:ring-slate-500">
                    <option value="">All statuses</option>
                    @foreach ($availableStatuses as $status)
                        <option value="{{ $status }}">{{ ucfirst($status) }}</option>
                    @endforeach
                </select>
            </label>

            <label class="space-y-2 text-sm text-slate-700">
                <span class="font-semibold text-slate-900">From</span>
                <input wire:model.live="dateFrom" type="date" class="w-full rounded-lg border-slate-300 text-sm shadow-sm focus:border-slate-500 focus:ring-slate-500" />
            </label>

            <label class="space-y-2 text-sm text-slate-700">
                <span class="font-semibold text-slate-900">To</span>
                <input wire:model.live="dateTo" type="date" class="w-full rounded-lg border-slate-300 text-sm shadow-sm focus:border-slate-500 focus:ring-slate-500" />
            </label>
        </div>

        <div class="overflow-x-auto">
            <table class="min-w-full divide-y divide-slate-200 text-sm">
                <thead class="bg-slate-950 text-left text-xs uppercase tracking-[0.18em] text-slate-200">
                    <tr>
                        <th class="px-4 py-3 font-semibold">
                            <button type="button" wire:click="sortBy('task_name')" class="inline-flex items-center gap-2">
                                Task <span>{{ $this->sortIndicator('task_name') }}</span>
                            </button>
                        </th>
                        <th class="px-4 py-3 font-semibold">
                            <button type="button" wire:click="sortBy('triggered_by')" class="inline-flex items-center gap-2">
                                Triggered By <span>{{ $this->sortIndicator('triggered_by') }}</span>
                            </button>
                        </th>
                        <th class="px-4 py-3 font-semibold">
                            <button type="button" wire:click="sortBy('status')" class="inline-flex items-center gap-2">
                                Status <span>{{ $this->sortIndicator('status') }}</span>
                            </button>
                        </th>
                        <th class="px-4 py-3 font-semibold">
                            <button type="button" wire:click="sortBy('started_at')" class="inline-flex items-center gap-2">
                                Started <span>{{ $this->sortIndicator('started_at') }}</span>
                            </button>
                        </th>
                        <th class="px-4 py-3 font-semibold">
                            <button type="button" wire:click="sortBy('duration_seconds')" class="inline-flex items-center gap-2">
                                Duration <span>{{ $this->sortIndicator('duration_seconds') }}</span>
                            </button>
                        </th>
                        <th class="px-4 py-3 font-semibold">Output</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-slate-200 bg-white text-slate-700">
                    @forelse ($deployments as $deployment)
                        <tr class="align-top">
                            <td class="px-4 py-4 font-medium text-slate-900">
                                @if ($deployment->task === null)
                                    Missing task record
                                @else
                                    <div>{{ $deployment->task->label }}</div>
                                    <div class="mt-1 text-xs font-normal text-slate-500">{{ $deployment->task->name }}</div>
                                @endif
                            </td>
                            <td class="px-4 py-4">{{ $deployment->triggered_by }}</td>
                            <td class="px-4 py-4">
                                <span class="inline-flex rounded-full bg-slate-100 px-3 py-1 text-xs font-semibold uppercase tracking-[0.16em] text-slate-700">
                                    {{ $deployment->status }}
                                </span>
                            </td>
                            <td class="px-4 py-4 text-slate-600">
                                @if ($deployment->started_at === null)
                                    Not started
                                @else
                                    {{ $deployment->started_at->format('Y-m-d H:i:s') }}
                                @endif
                            </td>
                            <td class="px-4 py-4 text-slate-600">{{ $this->durationText($deployment) }}</td>
                            <td class="px-4 py-4">
                                <button type="button" wire:click="toggleOutput({{ $deployment->id }})" class="inline-flex items-center rounded-md border border-slate-300 px-3 py-2 text-xs font-semibold text-slate-700 transition hover:bg-slate-100">
                                    {{ $this->isExpanded($deployment->id) ? 'Hide' : 'Show' }} output
                                </button>
                            </td>
                        </tr>

                        @if ($this->isExpanded($deployment->id))
                            <tr class="bg-slate-50">
                                <td colspan="6" class="px-4 py-4">
                                    <div class="rounded-lg border border-slate-200 bg-slate-950 p-4 text-sm text-slate-100">
                                        @if ($deployment->output === null || trim($deployment->output) === '')
                                            <p>No output was captured for this deployment.</p>
                                        @else
                                            <pre class="overflow-x-auto whitespace-pre-wrap font-mono text-xs leading-6">{{ $deployment->output }}</pre>
                                        @endif
                                    </div>
                                </td>
                            </tr>
                        @endif
                    @empty
                        <tr>
                            <td colspan="6" class="px-4 py-10 text-center text-sm text-slate-500">
                                No deployments match the selected filters.
                            </td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
    </div>
</div>