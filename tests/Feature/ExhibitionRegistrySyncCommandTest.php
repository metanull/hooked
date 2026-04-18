<?php

namespace Tests\Feature;

use App\Models\Exhibition;
use App\Services\PowerShellService;
use App\Services\ProcessResult;
use Illuminate\Foundation\Testing\RefreshDatabase;
use RuntimeException;
use Tests\TestCase;

class ExhibitionRegistrySyncCommandTest extends TestCase
{
    use RefreshDatabase;

    public function test_exhibitions_sync_upserts_registry_records_into_sqlite(): void
    {
        $payload = json_encode([
            [
                'Name' => 'arts_in_dialogue',
                'LanguageId' => 'de',
                'Status' => 'Installed',
                'ApiEnvironment' => [
                    'APP_NAME' => 'Dialogue',
                ],
                'ClientEnvironment' => [
                    'VITE_APP_NAME' => 'Dialogue',
                ],
            ],
            [
                'Name' => 'colors_of_history',
                'LanguageId' => 'en',
                'Status' => 'Published',
                'ApiEnvironment' => [
                    'APP_NAME' => 'Colors',
                ],
                'ClientEnvironment' => [
                    'VITE_APP_NAME' => 'Colors',
                ],
            ],
        ], JSON_THROW_ON_ERROR);

        $this->app->instance(PowerShellService::class, new class ('powershell', 'C:\\mwnf\\Launcher.ps1', 'env', 'config/site/powershell.php', false, $payload) extends PowerShellService {
            public function __construct(string $executable, ?string $launcherPath, string $configurationSource, string $siteConfigPath, bool $usedDefaultExecutable, private readonly string $payload)
            {
                parent::__construct($executable, $launcherPath, $configurationSource, $siteConfigPath, $usedDefaultExecutable);
            }

            public function run(string $command, ?int $timeout = null): ProcessResult
            {
                return new ProcessResult(0, $this->payload, '');
            }
        });

        $this->artisan('exhibitions:sync')
            ->expectsOutput('Synchronized 2 exhibition records from the registry.')
            ->assertSuccessful();

        $this->assertDatabaseHas('exhibitions', [
            'name' => 'arts_in_dialogue',
            'language_id' => 'de',
            'status' => 'Installed',
        ]);
        $this->assertDatabaseHas('exhibitions', [
            'name' => 'colors_of_history',
            'language_id' => 'en',
            'status' => 'Published',
        ]);

        $exhibition = Exhibition::query()->where('name', 'arts_in_dialogue')->where('language_id', 'de')->first();

        $this->assertInstanceOf(Exhibition::class, $exhibition);
        $this->assertSame(['APP_NAME' => 'Dialogue'], $exhibition->api_env);
        $this->assertSame(['VITE_APP_NAME' => 'Dialogue'], $exhibition->client_env);
        $this->assertNotNull($exhibition->synced_at);
    }

    public function test_exhibitions_sync_rejects_invalid_registry_records(): void
    {
        $payload = json_encode([
            'Name' => 'Invalid Exhibition Name',
            'LanguageId' => 'english',
            'Status' => 'Installed',
            'ApiEnvironment' => [
                'APP_NAME' => 'Broken',
            ],
            'ClientEnvironment' => [
                'VITE_APP_NAME' => 'Broken',
            ],
        ], JSON_THROW_ON_ERROR);

        $this->app->instance(PowerShellService::class, new class ('powershell', 'C:\\mwnf\\Launcher.ps1', 'env', 'config/site/powershell.php', false, $payload) extends PowerShellService {
            public function __construct(string $executable, ?string $launcherPath, string $configurationSource, string $siteConfigPath, bool $usedDefaultExecutable, private readonly string $payload)
            {
                parent::__construct($executable, $launcherPath, $configurationSource, $siteConfigPath, $usedDefaultExecutable);
            }

            public function run(string $command, ?int $timeout = null): ProcessResult
            {
                return new ProcessResult(0, $this->payload, '');
            }
        });

        $this->expectException(RuntimeException::class);
        $this->expectExceptionMessage('Exhibition registry record validation failed.');

        $this->artisan('exhibitions:sync')->run();
    }
}