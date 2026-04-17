<form wire:submit="save" class="space-y-6 rounded-xl border border-slate-200 bg-white p-6 shadow-sm">
    @if ($errors->any())
        <div class="rounded-lg border border-rose-200 bg-rose-50 px-4 py-3 text-sm text-rose-800">
            <p class="font-semibold">The exhibition configuration could not be saved.</p>
            <ul class="mt-2 list-disc pl-5">
                @foreach ($errors->all() as $error)
                    <li>{{ $error }}</li>
                @endforeach
            </ul>
        </div>
    @endif

    <div class="grid gap-6 md:grid-cols-2">
        <div>
            <label for="exhibition-name" class="block text-sm font-semibold text-slate-900">Name</label>
            <input
                id="exhibition-name"
                type="text"
                wire:model.defer="name"
                @readonly($editMode)
                class="mt-2 block w-full rounded-lg border-slate-300 text-sm shadow-sm focus:border-slate-500 focus:ring-slate-500"
            >
            <p class="mt-2 text-xs text-slate-500">Must match <span class="font-mono">^[a-z][a-z0-9_-]+[a-z]$</span>.</p>
        </div>

        <div>
            <label for="exhibition-language" class="block text-sm font-semibold text-slate-900">Language Id</label>
            <input
                id="exhibition-language"
                type="text"
                wire:model.defer="languageId"
                @readonly($editMode)
                class="mt-2 block w-full rounded-lg border-slate-300 text-sm shadow-sm focus:border-slate-500 focus:ring-slate-500"
            >
            <p class="mt-2 text-xs text-slate-500">Must match <span class="font-mono">^[a-z]{2}$</span>.</p>
        </div>
    </div>

    <div>
        <label for="exhibition-api-environment" class="block text-sm font-semibold text-slate-900">API Environment</label>
        <textarea
            id="exhibition-api-environment"
            wire:model.defer="apiEnvironment"
            rows="14"
            class="mt-2 block w-full rounded-lg border-slate-300 font-mono text-sm shadow-sm focus:border-slate-500 focus:ring-slate-500"
        ></textarea>
    </div>

    <div>
        <label for="exhibition-client-environment" class="block text-sm font-semibold text-slate-900">Client Environment</label>
        <textarea
            id="exhibition-client-environment"
            wire:model.defer="clientEnvironment"
            rows="14"
            class="mt-2 block w-full rounded-lg border-slate-300 font-mono text-sm shadow-sm focus:border-slate-500 focus:ring-slate-500"
        ></textarea>
    </div>

    <div class="flex items-center gap-3">
        <button type="submit" class="inline-flex items-center rounded-lg bg-slate-900 px-4 py-2 text-sm font-semibold text-white shadow-sm transition hover:bg-slate-700">
            Save
        </button>

        <a href="{{ route('exhibitions.index') }}" class="inline-flex items-center rounded-lg border border-slate-300 px-4 py-2 text-sm font-semibold text-slate-700 transition hover:bg-slate-100">
            Cancel
        </a>
    </div>
</form>