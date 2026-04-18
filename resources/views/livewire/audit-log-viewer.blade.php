<div class="rounded-xl border border-slate-200 bg-white p-6 shadow-sm">
    <div class="flex flex-col gap-6">
        <div>
            <p class="text-sm font-semibold uppercase tracking-[0.2em] text-slate-500">Audit Log</p>
            <h3 class="mt-2 text-2xl font-semibold text-slate-900">Operational audit trail</h3>
            <p class="mt-2 max-w-3xl text-sm text-slate-600">
                Inspect authenticated actions and webhook activity, then expand rows to review the structured payload captured for each entry.
            </p>
        </div>

        <div class="grid gap-4 rounded-xl border border-slate-200 bg-slate-50 p-4 md:grid-cols-2 xl:grid-cols-4">
            <label class="space-y-2 text-sm text-slate-700 xl:col-span-2">
                <span class="font-semibold text-slate-900">User</span>
                <input wire:model.live="userFilter" type="text" class="w-full rounded-lg border-slate-300 text-sm shadow-sm focus:border-slate-500 focus:ring-slate-500" placeholder="Filter by email or actor" />
            </label>

            <label class="space-y-2 text-sm text-slate-700">
                <span class="font-semibold text-slate-900">Action</span>
                <select wire:model.live="actionFilter" class="w-full rounded-lg border-slate-300 text-sm shadow-sm focus:border-slate-500 focus:ring-slate-500">
                    <option value="">All actions</option>
                    @foreach ($availableActions as $action)
                        <option value="{{ $action }}">{{ $action }}</option>
                    @endforeach
                </select>
            </label>

            <div class="grid gap-4 md:grid-cols-2 xl:col-span-1">
                <label class="space-y-2 text-sm text-slate-700">
                    <span class="font-semibold text-slate-900">From</span>
                    <input wire:model.live="dateFrom" type="date" class="w-full rounded-lg border-slate-300 text-sm shadow-sm focus:border-slate-500 focus:ring-slate-500" />
                </label>

                <label class="space-y-2 text-sm text-slate-700">
                    <span class="font-semibold text-slate-900">To</span>
                    <input wire:model.live="dateTo" type="date" class="w-full rounded-lg border-slate-300 text-sm shadow-sm focus:border-slate-500 focus:ring-slate-500" />
                </label>
            </div>
        </div>

        <div class="overflow-x-auto">
            <table class="min-w-full divide-y divide-slate-200 text-sm">
                <thead class="bg-slate-950 text-left text-xs uppercase tracking-[0.18em] text-slate-200">
                    <tr>
                        <th class="px-4 py-3 font-semibold">Timestamp</th>
                        <th class="px-4 py-3 font-semibold">User</th>
                        <th class="px-4 py-3 font-semibold">Action</th>
                        <th class="px-4 py-3 font-semibold">Target</th>
                        <th class="px-4 py-3 font-semibold">Payload</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-slate-200 bg-white text-slate-700">
                    @forelse ($auditEntries as $auditEntry)
                        <tr class="align-top">
                            <td class="px-4 py-4 text-slate-600">{{ $auditEntry->created_at->format('Y-m-d H:i:s') }}</td>
                            <td class="px-4 py-4">
                                @if ($auditEntry->user === null || trim($auditEntry->user) === '')
                                    <span class="text-slate-500">Guest / webhook</span>
                                @else
                                    {{ $auditEntry->user }}
                                @endif
                            </td>
                            <td class="px-4 py-4 font-medium text-slate-900">{{ $auditEntry->action }}</td>
                            <td class="px-4 py-4 text-slate-600">{{ $auditEntry->target }}</td>
                            <td class="px-4 py-4">
                                <button type="button" wire:click="togglePayload({{ $auditEntry->id }})" class="inline-flex items-center rounded-md border border-slate-300 px-3 py-2 text-xs font-semibold text-slate-700 transition hover:bg-slate-100">
                                    {{ $this->isExpanded($auditEntry->id) ? 'Hide' : 'Show' }} payload
                                </button>
                            </td>
                        </tr>

                        @if ($this->isExpanded($auditEntry->id))
                            <tr class="bg-slate-50">
                                <td colspan="5" class="px-4 py-4">
                                    <div class="rounded-lg border border-slate-200 bg-slate-950 p-4 text-sm text-slate-100">
                                        @if ($auditEntry->payload === null)
                                            <p>No payload was stored for this audit entry.</p>
                                        @else
                                            <pre class="overflow-x-auto whitespace-pre-wrap font-mono text-xs leading-6">{{ $this->payloadJson($auditEntry) }}</pre>
                                        @endif
                                    </div>
                                </td>
                            </tr>
                        @endif
                    @empty
                        <tr>
                            <td colspan="5" class="px-4 py-10 text-center text-sm text-slate-500">
                                No audit entries match the selected filters.
                            </td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
    </div>
</div>