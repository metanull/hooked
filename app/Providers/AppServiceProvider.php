<?php

namespace App\Providers;

use App\Services\PowerShellService;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        $this->app->singleton(PowerShellService::class, function (): PowerShellService {
            $configuration = config('powershell');

            if (! is_array($configuration)) {
                throw new \RuntimeException('PowerShell configuration must be an array.');
            }

            $executable = '';

            if (array_key_exists('executable', $configuration) && is_string($configuration['executable'])) {
                $executable = $configuration['executable'];
            }

            $launcherPath = null;

            if (array_key_exists('launcher_path', $configuration) && is_string($configuration['launcher_path']) && trim($configuration['launcher_path']) !== '') {
                $launcherPath = $configuration['launcher_path'];
            }

            $configurationSource = 'env';

            if (array_key_exists('source', $configuration) && is_string($configuration['source'])) {
                $configurationSource = $configuration['source'];
            }

            $sitePath = '';

            if (array_key_exists('site_path', $configuration) && is_string($configuration['site_path'])) {
                $sitePath = $configuration['site_path'];
            }

            $usedDefaultExecutable = false;

            if (array_key_exists('used_default_executable', $configuration)) {
                $usedDefaultExecutable = (bool) $configuration['used_default_executable'];
            }

            return new PowerShellService($executable, $launcherPath, $configurationSource, $sitePath, $usedDefaultExecutable);
        });
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        //
    }
}
