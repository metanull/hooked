<?php

namespace Tests\Feature;

use App\Livewire\ExhibitionList;
use App\Models\Exhibition;
use App\Models\User;
use App\Services\Exhibitions\ExhibitionRegistrySyncService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Livewire\Livewire;
use Tests\TestCase;

class ExhibitionListTest extends TestCase
{
    use RefreshDatabase;

    public function test_exhibition_list_page_requires_authentication(): void
    {
        $this->get('/admin/exhibitions')->assertRedirect('/login');
    }

    public function test_exhibition_list_component_renders_synced_exhibitions(): void
    {
        Exhibition::query()->create([
            'name' => 'arts_in_dialogue',
            'language_id' => 'de',
            'status' => 'Installed',
            'api_env' => ['APP_NAME' => 'Dialogue'],
            'client_env' => ['VITE_APP_NAME' => 'Dialogue'],
            'synced_at' => now(),
        ]);

        Livewire::test(ExhibitionList::class)
            ->assertSee('arts_in_dialogue')
            ->assertSee('de')
            ->assertSee('Installed')
            ->assertSee('Configure')
            ->assertSee('Publish All');
    }

    public function test_refresh_button_runs_the_registry_sync_service(): void
    {
        $this->app->instance(ExhibitionRegistrySyncService::class, new class extends ExhibitionRegistrySyncService {
            public function __construct()
            {
            }

            public function sync(): int
            {
                Exhibition::query()->create([
                    'name' => 'queued_history',
                    'language_id' => 'fr',
                    'status' => 'Installed',
                    'api_env' => ['APP_NAME' => 'Queued History'],
                    'client_env' => ['VITE_APP_NAME' => 'Queued History'],
                    'synced_at' => now(),
                ]);

                return 3;
            }
        });

        Livewire::test(ExhibitionList::class)
            ->call('refreshFromRegistry')
            ->assertSee('queued_history')
            ->assertSee('fr');
    }

    public function test_authenticated_user_can_open_the_exhibition_list_page(): void
    {
        $user = User::factory()->create();

        $this->actingAs($user)
            ->get('/admin/exhibitions')
            ->assertOk()
            ->assertSeeLivewire('exhibition-list');
    }
}