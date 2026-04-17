<?php

namespace App\Livewire;

use App\Models\Exhibition;
use App\Services\Exhibitions\ExhibitionQueueService;
use App\Services\Exhibitions\ExhibitionQueueStatusService;
use App\Services\Exhibitions\ExhibitionRegistrySyncService;
use Illuminate\Contracts\View\View;
use Livewire\Component;

class ExhibitionList extends Component
{
    public bool $syncing = false;

    public string $queueRunnerState = 'Ready';

    public bool $queueRunnerBusy = false;

    /**
     * @var array<int, array{id: string, command: string}>
     */
    public array $pendingQueueCommands = [];

    public function mount(): void
    {
        $this->reloadQueueState();
    }

    public function publishDemo(int $exhibitionId, ExhibitionQueueService $queueService): void
    {
        $queueService->publishDemo($this->findExhibition($exhibitionId));
        $this->reloadQueueState();
        session()->flash('status', 'Queued demo publish for the selected exhibition.');
    }

    public function unpublishDemo(int $exhibitionId, ExhibitionQueueService $queueService): void
    {
        $queueService->unpublishDemo($this->findExhibition($exhibitionId));
        $this->reloadQueueState();
        session()->flash('status', 'Queued demo unpublish for the selected exhibition.');
    }

    public function publishLive(int $exhibitionId, ExhibitionQueueService $queueService): void
    {
        $queueService->publishLive($this->findExhibition($exhibitionId));
        $this->reloadQueueState();
        session()->flash('status', 'Queued live publish for the selected exhibition.');
    }

    public function unpublishLive(int $exhibitionId, ExhibitionQueueService $queueService): void
    {
        $queueService->unpublishLive($this->findExhibition($exhibitionId));
        $this->reloadQueueState();
        session()->flash('status', 'Queued live unpublish for the selected exhibition.');
    }

    public function uninstall(int $exhibitionId, ExhibitionQueueService $queueService): void
    {
        $queueService->uninstall($this->findExhibition($exhibitionId));
        $this->reloadQueueState();
        session()->flash('status', 'Queued exhibition uninstall.');
    }

    public function publishAll(ExhibitionQueueService $queueService): void
    {
        $queueService->publishAll(Exhibition::query()->orderBy('name')->orderBy('language_id')->get());
        $this->reloadQueueState();
        session()->flash('status', 'Queued publish-all exhibition workflow.');
    }

    public function refreshQueueState(): void
    {
        $this->reloadQueueState();
    }

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

    private function findExhibition(int $exhibitionId): Exhibition
    {
        $exhibition = Exhibition::query()->find($exhibitionId);

        if (! $exhibition instanceof Exhibition) {
            abort(404);
        }

        return $exhibition;
    }

    private function reloadQueueState(): void
    {
        $queueState = app(ExhibitionQueueStatusService::class)->readState();

        $this->queueRunnerState = $queueState['state'];
        $this->queueRunnerBusy = $queueState['busy'];
        $this->pendingQueueCommands = $queueState['pending_commands'];
    }
}