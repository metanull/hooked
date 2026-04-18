<?php

namespace Tests\Feature;

use App\Livewire\ExhibitionList;
use App\Models\Exhibition;
use App\Models\User;
use App\Services\Exhibitions\ExhibitionQueueService;
use App\Services\Exhibitions\ExhibitionQueueStatusService;
use App\Services\Exhibitions\ExhibitionRegistrySyncService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Livewire\Livewire;
use Tests\TestCase;

class ExhibitionListTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->app->instance(ExhibitionQueueStatusService::class, new class extends ExhibitionQueueStatusService {
            public function __construct()
            {
            }

            public function readState(): array
            {
                return [
                    'state' => 'Ready',
                    'busy' => false,
                    'pending_commands' => [],
                ];
            }
        });
    }

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

    public function test_individual_action_buttons_call_the_queue_service(): void
    {
        $exhibition = Exhibition::query()->create([
            'name' => 'arts_in_dialogue',
            'language_id' => 'de',
            'status' => 'Installed',
            'api_env' => ['APP_NAME' => 'Dialogue'],
            'client_env' => ['VITE_APP_NAME' => 'Dialogue'],
            'synced_at' => now(),
        ]);
        $user = User::factory()->create([
            'email' => 'operator@example.test',
        ]);
        $queueService = new class extends ExhibitionQueueService {
            /**
             * @var array<int, string>
             */
            public array $operations = [];

            public function __construct()
            {
            }

            public function publishDemo(Exhibition $exhibition): void
            {
                $this->operations[] = 'publishDemo:'.$exhibition->name.':'.$exhibition->language_id;
            }

            public function unpublishDemo(Exhibition $exhibition): void
            {
                $this->operations[] = 'unpublishDemo:'.$exhibition->name.':'.$exhibition->language_id;
            }

            public function publishLive(Exhibition $exhibition): void
            {
                $this->operations[] = 'publishLive:'.$exhibition->name.':'.$exhibition->language_id;
            }

            public function unpublishLive(Exhibition $exhibition): void
            {
                $this->operations[] = 'unpublishLive:'.$exhibition->name.':'.$exhibition->language_id;
            }

            public function uninstall(Exhibition $exhibition): void
            {
                $this->operations[] = 'uninstall:'.$exhibition->name.':'.$exhibition->language_id;
            }
        };
        $this->app->instance(ExhibitionQueueService::class, $queueService);

        Livewire::actingAs($user)
            ->test(ExhibitionList::class)
            ->call('publishDemo', $exhibition->id)
            ->call('unpublishDemo', $exhibition->id)
            ->call('publishLive', $exhibition->id)
            ->call('unpublishLive', $exhibition->id)
            ->call('uninstall', $exhibition->id);

        $this->assertSame([
            'publishDemo:arts_in_dialogue:de',
            'unpublishDemo:arts_in_dialogue:de',
            'publishLive:arts_in_dialogue:de',
            'unpublishLive:arts_in_dialogue:de',
            'uninstall:arts_in_dialogue:de',
        ], $queueService->operations);
        $this->assertDatabaseCount('audit_log', 5);
        $this->assertDatabaseHas('audit_log', [
            'user' => 'operator@example.test',
            'action' => 'exhibition.publish_requested',
            'target' => 'arts_in_dialogue:de',
        ]);
        $this->assertDatabaseHas('audit_log', [
            'user' => 'operator@example.test',
            'action' => 'exhibition.unpublish_requested',
            'target' => 'arts_in_dialogue:de',
        ]);
        $this->assertDatabaseHas('audit_log', [
            'user' => 'operator@example.test',
            'action' => 'exhibition.deleted',
            'target' => 'arts_in_dialogue:de',
        ]);
    }

    public function test_publish_all_queues_demo_for_every_exhibition_and_skips_live_for_test_names(): void
    {
        Exhibition::query()->create([
            'name' => 'arts_in_dialogue',
            'language_id' => 'de',
            'status' => 'Installed',
            'api_env' => ['APP_NAME' => 'Dialogue'],
            'client_env' => ['VITE_APP_NAME' => 'Dialogue'],
            'synced_at' => now(),
        ]);
        Exhibition::query()->create([
            'name' => 'playground_gallery',
            'language_id' => 'en',
            'status' => 'Installed',
            'api_env' => ['APP_NAME' => 'Playground'],
            'client_env' => ['VITE_APP_NAME' => 'Playground'],
            'synced_at' => now(),
        ]);
        $queueService = new class extends ExhibitionQueueService {
            /**
             * @var array<int, string>
             */
            public array $operations = [];

            public function __construct()
            {
            }

            public function publishAll(\Illuminate\Support\Collection $exhibitions): void
            {
                foreach ($exhibitions as $exhibition) {
                    if (! $exhibition instanceof Exhibition) {
                        continue;
                    }

                    $this->operations[] = 'demo:'.$exhibition->name;

                    if (preg_match('/(demo|test|playground)/i', $exhibition->name) !== 1) {
                        $this->operations[] = 'live:'.$exhibition->name;
                    }
                }
            }
        };
        $this->app->instance(ExhibitionQueueService::class, $queueService);

        Livewire::test(ExhibitionList::class)
            ->call('publishAll');

        $this->assertSame([
            'demo:arts_in_dialogue',
            'live:arts_in_dialogue',
            'demo:playground_gallery',
        ], $queueService->operations);
    }

    public function test_queue_status_panel_shows_pending_commands_and_busy_state(): void
    {
        $this->app->instance(ExhibitionQueueStatusService::class, new class extends ExhibitionQueueStatusService {
            public function __construct()
            {
            }

            public function readState(): array
            {
                return [
                    'state' => 'Running',
                    'busy' => true,
                    'pending_commands' => [
                        ['id' => '169', 'command' => 'Publish-MWNFExhibition -Name arts_in_dialogue -LanguageId de -Demo'],
                        ['id' => '170', 'command' => 'Publish-MWNFExhibition -Name arts_in_dialogue -LanguageId de'],
                    ],
                ];
            }
        });

        Livewire::test(ExhibitionList::class)
            ->assertSet('queueRunnerState', 'Running')
            ->assertSet('queueRunnerBusy', true)
            ->assertSee('Pending Commands')
            ->assertSee('Queue Item 169')
            ->assertSee('Publish-MWNFExhibition -Name arts_in_dialogue -LanguageId de -Demo');
    }
}