<div class="space-y-6" @if ($queueRunnerBusy) wire:poll.2s="refreshQueueState" @endif>
    @if (session('status'))
        <div class="rounded-lg border border-emerald-200 bg-emerald-50 px-4 py-3 text-sm text-emerald-800">
            {{ session('status') }}
        </div>
    @endif

    <div class="rounded-xl border border-slate-200 bg-white p-5 shadow-sm">
        <div class="flex flex-col gap-4 md:flex-row md:items-start md:justify-between">
            <div>
                <p class="text-sm font-semibold uppercase tracking-[0.2em] text-slate-500">Queue Runner</p>
                <div class="mt-2 flex items-center gap-3">
                    @if ($queueRunnerBusy)
                        <span class="inline-flex h-3 w-3 animate-pulse rounded-full bg-amber-500"></span>
                    @else
                        <span class="inline-flex h-3 w-3 rounded-full bg-emerald-500"></span>
                    @endif

                    <p class="text-sm font-semibold text-slate-900">{{ $queueRunnerState }}</p>
                </div>
                <p class="mt-2 text-sm text-slate-600">
                    @if ($queueRunnerBusy)
                        Queue polling is active every 2 seconds while the runner is busy.
                    @else
                        Queue polling is paused while the runner is idle.
                    @endif
                </p>
            </div>

            <button
                type="button"
                wire:click="refreshQueueState"
                class="inline-flex items-center rounded-lg border border-slate-300 bg-white px-4 py-2 text-sm font-semibold text-slate-700 shadow-sm transition hover:bg-slate-100"
            >
                Refresh Queue State
            </button>
        </div>

        <div class="mt-5 rounded-lg border border-slate-200 bg-slate-50 p-4">
            <p class="text-sm font-semibold text-slate-900">Pending Commands</p>

            @if ($pendingQueueCommands === [])
                <p class="mt-2 text-sm text-slate-500">The queue is currently empty.</p>
            @else
                <ul class="mt-3 space-y-3">
                    @foreach ($pendingQueueCommands as $queueCommand)
                        <li class="rounded-lg border border-slate-200 bg-white px-4 py-3">
                            <p class="text-xs font-semibold uppercase tracking-[0.18em] text-slate-500">Queue Item {{ $queueCommand['id'] }}</p>
                            <p class="mt-2 break-all font-mono text-sm text-slate-800">{{ $queueCommand['command'] }}</p>
                        </li>
                    @endforeach
                </ul>
            @endif
        </div>
    </div>

    <div class="overflow-hidden rounded-xl border border-slate-200 bg-white shadow-sm">
        <div class="flex flex-col gap-4 border-b border-slate-200 bg-slate-50 px-6 py-5 md:flex-row md:items-center md:justify-between">
            <div>
                <p class="text-sm font-semibold uppercase tracking-[0.2em] text-slate-500">Exhibitions</p>
                <h3 class="mt-1 text-xl font-semibold text-slate-900">Registry-backed exhibition management</h3>
            </div>

            <div class="flex flex-wrap gap-3">
                <a href="{{ route('exhibitions.create') }}" class="inline-flex items-center rounded-lg bg-slate-900 px-4 py-2 text-sm font-semibold text-white shadow-sm transition hover:bg-slate-700">
                    Create
                </a>

                <button
                    type="button"
                    wire:click="refreshFromRegistry"
                    wire:loading.attr="disabled"
                    class="inline-flex items-center rounded-lg border border-slate-300 bg-white px-4 py-2 text-sm font-semibold text-slate-700 shadow-sm transition hover:bg-slate-100 disabled:cursor-not-allowed disabled:opacity-60"
                >
                    <span wire:loading.remove wire:target="refreshFromRegistry">Refresh</span>
                    <span wire:loading wire:target="refreshFromRegistry">Refreshing...</span>
                </button>

                <button
                    type="button"
                    wire:click="publishAll"
                    class="inline-flex items-center rounded-lg border border-amber-300 bg-amber-50 px-4 py-2 text-sm font-semibold text-amber-700 shadow-sm transition hover:bg-amber-100"
                >
                    Publish All
                </button>
            </div>
        </div>

        <div class="overflow-x-auto">
            <table class="min-w-full divide-y divide-slate-200 text-sm">
                <thead class="bg-slate-950 text-left text-xs uppercase tracking-[0.18em] text-slate-200">
                    <tr>
                        <th class="px-4 py-3 font-semibold">Name</th>
                        <th class="px-4 py-3 font-semibold">Language</th>
                        <th class="px-4 py-3 font-semibold">Status</th>
                        <th class="px-4 py-3 font-semibold">Setup Actions</th>
                        <th class="px-4 py-3 font-semibold">Demo Actions</th>
                        <th class="px-4 py-3 font-semibold">Live Actions</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-slate-200 bg-white text-slate-700">
                    @forelse ($exhibitions as $exhibition)
                        <tr class="align-top">
                            <td class="px-4 py-4 font-medium text-slate-900">{{ $exhibition->name }}</td>
                            <td class="px-4 py-4">{{ $exhibition->language_id }}</td>
                            <td class="px-4 py-4">
                                <span class="inline-flex rounded-full bg-slate-100 px-3 py-1 text-xs font-semibold uppercase tracking-[0.16em] text-slate-700">
                                    {{ $exhibition->status }}
                                </span>
                            </td>
                            <td class="px-4 py-4">
                                <div class="flex flex-wrap gap-2">
                                    <a href="{{ route('exhibitions.edit', ['name' => $exhibition->name, 'languageId' => $exhibition->language_id]) }}" class="inline-flex items-center rounded-md bg-blue-600 px-3 py-2 text-xs font-semibold text-white transition hover:bg-blue-500">
                                        Configure
                                    </a>
                                    <button type="button" wire:click="uninstall({{ $exhibition->id }})" class="inline-flex items-center rounded-md bg-rose-100 px-3 py-2 text-xs font-semibold text-rose-700 transition hover:bg-rose-200">
                                        Uninstall
                                    </button>
                                </div>
                            </td>
                            <td class="px-4 py-4">
                                <div class="flex flex-wrap gap-2">
                                    <button type="button" wire:click="publishDemo({{ $exhibition->id }})" class="inline-flex items-center rounded-md bg-emerald-100 px-3 py-2 text-xs font-semibold text-emerald-700 transition hover:bg-emerald-200">
                                        Publish
                                    </button>
                                    <button type="button" wire:click="unpublishDemo({{ $exhibition->id }})" class="inline-flex items-center rounded-md bg-amber-100 px-3 py-2 text-xs font-semibold text-amber-700 transition hover:bg-amber-200">
                                        Unpublish
                                    </button>
                                    <a href="{{ rtrim((string) $demoBaseUrl, '/') }}/{{ $exhibition->name }}/{{ $exhibition->language_id }}" target="_blank" rel="noreferrer" class="inline-flex items-center rounded-md border border-slate-300 px-3 py-2 text-xs font-semibold text-slate-700 transition hover:bg-slate-100">
                                        Open
                                    </a>
                                </div>
                            </td>
                            <td class="px-4 py-4">
                                <div class="flex flex-wrap gap-2">
                                    <button type="button" wire:click="publishLive({{ $exhibition->id }})" class="inline-flex items-center rounded-md bg-emerald-100 px-3 py-2 text-xs font-semibold text-emerald-700 transition hover:bg-emerald-200">
                                        Publish
                                    </button>
                                    <button type="button" wire:click="unpublishLive({{ $exhibition->id }})" class="inline-flex items-center rounded-md bg-amber-100 px-3 py-2 text-xs font-semibold text-amber-700 transition hover:bg-amber-200">
                                        Unpublish
                                    </button>
                                    <a href="{{ rtrim((string) $liveBaseUrl, '/') }}/{{ $exhibition->name }}/{{ $exhibition->language_id }}" target="_blank" rel="noreferrer" class="inline-flex items-center rounded-md border border-slate-300 px-3 py-2 text-xs font-semibold text-slate-700 transition hover:bg-slate-100">
                                        Open
                                    </a>
                                </div>
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="6" class="px-4 py-10 text-center text-sm text-slate-500">
                                No exhibitions are synced yet. Use Refresh to pull the registry state into SQLite.
                            </td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
    </div>
</div>