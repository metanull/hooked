<x-app-layout>
    <x-slot name="header">
        <h2 class="font-semibold text-xl text-gray-800 leading-tight">
            {{ isset($name, $languageId) ? __('Configure Exhibition') : __('Create Exhibition') }}
        </h2>
    </x-slot>

    <div class="py-12">
        <div class="mx-auto max-w-5xl px-4 sm:px-6 lg:px-8">
            <livewire:exhibition-form :name="$name ?? null" :language-id="$languageId ?? null" />
        </div>
    </div>
</x-app-layout>