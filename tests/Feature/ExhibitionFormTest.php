<?php

namespace Tests\Feature;

use App\Livewire\ExhibitionForm;
use App\Models\Exhibition;
use App\Services\Exhibitions\ExhibitionConfigurationService;
use App\Services\Exhibitions\ExhibitionRegistrySyncService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Livewire\Livewire;
use Tests\TestCase;

class ExhibitionFormTest extends TestCase
{
    use RefreshDatabase;

    public function test_create_mode_starts_with_editing_enabled_fields(): void
    {
        Livewire::test(ExhibitionForm::class)
            ->assertSet('editMode', false)
            ->assertSet('name', '')
            ->assertSet('languageId', '');
    }

    public function test_edit_mode_loads_the_existing_exhibition_configuration(): void
    {
        Exhibition::query()->create([
            'name' => 'arts_in_dialogue',
            'language_id' => 'de',
            'status' => 'Installed',
            'api_env' => ['APP_NAME' => 'Dialogue'],
            'client_env' => ['VITE_APP_NAME' => 'Dialogue'],
            'synced_at' => now(),
        ]);

        Livewire::test(ExhibitionForm::class, ['name' => 'arts_in_dialogue', 'languageId' => 'de'])
            ->assertSet('editMode', true)
            ->assertSet('name', 'arts_in_dialogue')
            ->assertSet('languageId', 'de')
            ->assertSet('apiEnvironment', 'APP_NAME=Dialogue')
            ->assertSet('clientEnvironment', 'VITE_APP_NAME=Dialogue');
    }

    public function test_save_calls_powershell_install_and_then_syncs_the_registry(): void
    {
        $configurationService = new class extends ExhibitionConfigurationService {
            public array $captured = [];

            public function __construct()
            {
            }

            public function install(string $name, string $languageId, string $apiEnvironment, string $clientEnvironment): void
            {
                $this->captured = [
                    'name' => $name,
                    'languageId' => $languageId,
                    'apiEnvironment' => $apiEnvironment,
                    'clientEnvironment' => $clientEnvironment,
                ];
            }
        };
        $syncService = new class extends ExhibitionRegistrySyncService {
            public int $calls = 0;

            public function __construct()
            {
            }

            public function sync(): int
            {
                $this->calls++;

                return 1;
            }
        };
        $this->app->instance(ExhibitionConfigurationService::class, $configurationService);
        $this->app->instance(ExhibitionRegistrySyncService::class, $syncService);

        Livewire::test(ExhibitionForm::class)
            ->set('name', 'arts_in_dialogue')
            ->set('languageId', 'de')
            ->set('apiEnvironment', "APP_NAME=Dialogue\nAPP_ENV=production")
            ->set('clientEnvironment', "VITE_APP_NAME=Dialogue")
            ->call('save')
            ->assertRedirect(route('exhibitions.index'));

        $this->assertSame([
            'name' => 'arts_in_dialogue',
            'languageId' => 'de',
            'apiEnvironment' => "APP_NAME=Dialogue\nAPP_ENV=production",
            'clientEnvironment' => 'VITE_APP_NAME=Dialogue',
        ], $configurationService->captured);
        $this->assertSame(1, $syncService->calls);
    }

    public function test_save_validates_the_name_and_language_id_patterns(): void
    {
        Livewire::test(ExhibitionForm::class)
            ->set('name', 'Invalid Exhibition')
            ->set('languageId', 'english')
            ->set('apiEnvironment', 'APP_NAME=Broken')
            ->set('clientEnvironment', 'VITE_APP_NAME=Broken')
            ->call('save')
            ->assertHasErrors(['name', 'languageId']);
    }
}