<?php

namespace App\Livewire;

use App\Models\Exhibition;
use App\Services\Exhibitions\ExhibitionConfigurationService;
use App\Services\Exhibitions\ExhibitionRegistrySyncService;
use Illuminate\Contracts\View\View;
use Livewire\Component;

class ExhibitionForm extends Component
{
    public string $name = '';

    public string $languageId = '';

    public string $apiEnvironment = '';

    public string $clientEnvironment = '';

    public bool $editMode = false;

    public function mount(?string $name = null, ?string $languageId = null): void
    {
        if ($name === null && $languageId === null) {
            $this->editMode = false;

            return;
        }

        if (! is_string($name) || ! is_string($languageId)) {
            abort(404);
        }

        $exhibition = Exhibition::query()
            ->where('name', $name)
            ->where('language_id', $languageId)
            ->first();

        if (! $exhibition instanceof Exhibition) {
            abort(404);
        }

        $this->editMode = true;
        $this->name = $exhibition->name;
        $this->languageId = $exhibition->language_id;
        $this->apiEnvironment = $this->stringifyEnvironment($exhibition->api_env);
        $this->clientEnvironment = $this->stringifyEnvironment($exhibition->client_env);
    }

    public function save(ExhibitionConfigurationService $configurationService, ExhibitionRegistrySyncService $syncService)
    {
        $validated = $this->validate($this->rules(), [], [
            'languageId' => 'language id',
            'apiEnvironment' => 'API environment',
            'clientEnvironment' => 'client environment',
        ]);

        $configurationService->install(
            $validated['name'],
            $validated['languageId'],
            $validated['apiEnvironment'],
            $validated['clientEnvironment'],
        );
        $syncService->sync();

        session()->flash('status', 'Exhibition configuration saved.');

        return $this->redirectRoute('exhibitions.index', navigate: false);
    }

    public function render(): View
    {
        return view('livewire.exhibition-form');
    }

    /**
     * @return array<string, array<int, string>>
     */
    protected function rules(): array
    {
        return [
            'name' => ['required', 'regex:'.Exhibition::NAME_PATTERN],
            'languageId' => ['required', 'regex:'.Exhibition::LANGUAGE_ID_PATTERN],
            'apiEnvironment' => ['required', 'string'],
            'clientEnvironment' => ['required', 'string'],
        ];
    }

    /**
     * @param  array<string, string>|null  $environment
     */
    private function stringifyEnvironment(?array $environment): string
    {
        if ($environment === null) {
            return '';
        }

        $lines = [];

        foreach ($environment as $key => $value) {
            if (! is_string($key)) {
                continue;
            }

            $lines[] = $key.'='.$value;
        }

        return implode(PHP_EOL, $lines);
    }
}