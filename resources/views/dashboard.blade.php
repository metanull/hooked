<x-app-layout>
    <x-slot name="header">
        <h2 class="font-semibold text-xl text-gray-800 leading-tight">
            {{ __('Task Dashboard') }}
        </h2>
    </x-slot>

    <div class="py-12">
        <div class="max-w-7xl mx-auto space-y-8 sm:px-6 lg:px-8">
            <livewire:task-dashboard />
            <livewire:deployment-history-viewer />
            <livewire:audit-log-viewer />
            <livewire:smtp-test-form />
        </div>
    </div>
</x-app-layout>
