<div class="rounded-xl border border-slate-200 bg-white p-6 shadow-sm">
    <div class="max-w-3xl">
        <p class="text-sm font-semibold uppercase tracking-[0.2em] text-slate-500">SMTP Test</p>
        <h3 class="mt-2 text-2xl font-semibold text-slate-900">Send a diagnostic email</h3>
        <p class="mt-2 text-sm text-slate-600">Use the configured Laravel mailer to send a test message through the current SMTP setup.</p>
    </div>

    @if (session('smtp-status'))
        <div class="mt-4 rounded-lg border border-emerald-200 bg-emerald-50 px-4 py-3 text-sm text-emerald-800">
            {{ session('smtp-status') }}
        </div>
    @endif

    @if ($errors->any())
        <div class="mt-4 rounded-lg border border-rose-200 bg-rose-50 px-4 py-3 text-sm text-rose-800">
            <ul class="list-disc pl-5">
                @foreach ($errors->all() as $error)
                    <li>{{ $error }}</li>
                @endforeach
            </ul>
        </div>
    @endif

    <form wire:submit="send" class="mt-6 space-y-5">
        <div class="grid gap-5 md:grid-cols-2">
            <div>
                <label for="smtp-to" class="block text-sm font-semibold text-slate-900">To</label>
                <input id="smtp-to" type="email" wire:model.defer="to" class="mt-2 block w-full rounded-lg border-slate-300 text-sm shadow-sm focus:border-slate-500 focus:ring-slate-500">
            </div>

            <div>
                <label for="smtp-subject" class="block text-sm font-semibold text-slate-900">Subject</label>
                <input id="smtp-subject" type="text" wire:model.defer="subject" class="mt-2 block w-full rounded-lg border-slate-300 text-sm shadow-sm focus:border-slate-500 focus:ring-slate-500">
            </div>
        </div>

        <div>
            <label for="smtp-body" class="block text-sm font-semibold text-slate-900">Body</label>
            <textarea id="smtp-body" wire:model.defer="body" rows="8" class="mt-2 block w-full rounded-lg border-slate-300 text-sm shadow-sm focus:border-slate-500 focus:ring-slate-500"></textarea>
        </div>

        <div class="grid gap-5 md:grid-cols-2">
            <fieldset>
                <legend class="text-sm font-semibold text-slate-900">Content-Type</legend>
                <div class="mt-3 flex flex-wrap gap-4 text-sm text-slate-700">
                    <label class="inline-flex items-center gap-2">
                        <input type="radio" wire:model.defer="contentType" value="text/plain" class="border-slate-300 text-slate-900 focus:ring-slate-500">
                        <span>TEXT</span>
                    </label>
                    <label class="inline-flex items-center gap-2">
                        <input type="radio" wire:model.defer="contentType" value="text/html" class="border-slate-300 text-slate-900 focus:ring-slate-500">
                        <span>HTML</span>
                    </label>
                </div>
            </fieldset>

            <fieldset>
                <legend class="text-sm font-semibold text-slate-900">Content-Transfer-Encoding</legend>
                <div class="mt-3 flex flex-wrap gap-4 text-sm text-slate-700">
                    <label class="inline-flex items-center gap-2">
                        <input type="radio" wire:model.defer="contentTransferEncoding" value="8bit" class="border-slate-300 text-slate-900 focus:ring-slate-500">
                        <span>8BIT</span>
                    </label>
                    <label class="inline-flex items-center gap-2">
                        <input type="radio" wire:model.defer="contentTransferEncoding" value="base64" class="border-slate-300 text-slate-900 focus:ring-slate-500">
                        <span>BASE64</span>
                    </label>
                </div>
            </fieldset>
        </div>

        <div>
            <button type="submit" class="inline-flex items-center rounded-lg bg-slate-900 px-4 py-2 text-sm font-semibold text-white transition hover:bg-slate-700">
                Send
            </button>
        </div>
    </form>
</div>