<div class="space-y-6">
    @if (session('status'))
        <div class="rounded-lg border border-emerald-200 bg-emerald-50 px-4 py-3 text-sm text-emerald-800">
            {{ session('status') }}
        </div>
    @endif

    <div class="rounded-xl border border-slate-200 bg-white p-6 shadow-sm">
        <p class="text-sm font-semibold uppercase tracking-[0.2em] text-slate-500">Task Dashboard</p>
        <h3 class="mt-2 text-2xl font-semibold text-slate-900">Operational scheduled tasks</h3>
        <p class="mt-2 max-w-3xl text-sm text-slate-600">
            This dashboard replaces the legacy jQuery accordion and groups the MWNF deployment tasks by directory.
        </p>
    </div>

    @foreach ($groupedTasks as $directory => $tasks)
        <details class="overflow-hidden rounded-xl border border-slate-200 bg-white shadow-sm" @if ($loop->first) open @endif>
            <summary class="cursor-pointer list-none border-b border-slate-200 bg-slate-50 px-6 py-4">
                <div class="flex items-center justify-between gap-4">
                    <div>
                        <p class="text-xs font-semibold uppercase tracking-[0.2em] text-slate-500">Directory</p>
                        <h4 class="mt-1 text-lg font-semibold text-slate-900">{{ ucfirst($directory) }}</h4>
                    </div>
                    <span class="inline-flex rounded-full bg-slate-200 px-3 py-1 text-xs font-semibold uppercase tracking-[0.16em] text-slate-700">
                        {{ $tasks->count() }} tasks
                    </span>
                </div>
            </summary>

            <div class="grid gap-4 px-6 py-6 md:grid-cols-2 xl:grid-cols-3">
                @foreach ($tasks as $task)
                    @php($tone = $this->badgeTone($task))
                    <div class="rounded-xl border border-slate-200 bg-slate-50 p-4">
                        <div class="flex items-start justify-between gap-3">
                            <div>
                                <p class="text-sm font-semibold text-slate-900">{{ $task->label }}</p>
                                <p class="mt-1 break-all text-xs text-slate-500">{{ $task->scheduled_task_path }}</p>
                            </div>

                            @if ($tone === 'green')
                                <span class="inline-flex rounded-full bg-emerald-100 px-3 py-1 text-xs font-semibold uppercase tracking-[0.16em] text-emerald-700">client</span>
                            @elseif ($tone === 'amber')
                                <span class="inline-flex rounded-full bg-amber-100 px-3 py-1 text-xs font-semibold uppercase tracking-[0.16em] text-amber-700">api</span>
                            @else
                                <span class="inline-flex rounded-full bg-slate-200 px-3 py-1 text-xs font-semibold uppercase tracking-[0.16em] text-slate-700">other</span>
                            @endif
                        </div>

                        <div class="mt-4 flex items-center justify-between gap-3">
                            <button type="button" wire:click="triggerTask({{ $task->id }})" class="inline-flex items-center rounded-lg bg-slate-900 px-4 py-2 text-sm font-semibold text-white transition hover:bg-slate-700">
                                Trigger
                            </button>

                            <span class="inline-flex rounded-full border border-slate-300 bg-white px-3 py-1 text-xs font-semibold uppercase tracking-[0.16em] text-slate-600">
                                {{ $this->statusText($task) }}
                            </span>
                        </div>

                        <p class="mt-3 text-xs text-slate-500">{{ $this->statusDetail($task) }}</p>
                    </div>
                @endforeach
            </div>
        </details>
    @endforeach
</div>