<?php

namespace App\Livewire;

use App\Models\Exhibition;
use App\Services\Exhibitions\ExhibitionRegistrySyncService;
use Illuminate\Contracts\View\View;
use Livewire\Component;

class ExhibitionList extends Component
{
    public bool $syncing = false;

    public function refreshFromRegistry(ExhibitionRegistrySyncService $syncService): void
    {
        $this->syncing = true;
        $count = $syncService->sync();
        $this->syncing = false;

        session()->flash('status', 'Synchronized '.$count.' exhibition records from the registry.');
    }

    public function render(): View
    {
        return view('livewire.exhibition-list', [
            'exhibitions' => Exhibition::query()->orderBy('name')->orderBy('language_id')->get(),
            'liveBaseUrl' => config('exhibitions.live_base_url'),
            'demoBaseUrl' => config('exhibitions.demo_base_url'),
        ]);
    }
}