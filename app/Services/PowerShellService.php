<?php

namespace App\Services;

use Illuminate\Support\Facades\Log;
use RuntimeException;
use Symfony\Component\Process\Process;

class PowerShellService
{
    public function __construct(
        private readonly string $executable,
        private readonly ?string $launcherPath,
        private readonly string $configurationSource,
        private readonly string $siteConfigPath,
        private readonly bool $usedDefaultExecutable,
    ) {
        if (trim($this->executable) === '') {
            throw new RuntimeException('PowerShell executable path must be configured.');
        }
    }

    public function run(string $command, ?int $timeout = null): ProcessResult
    {
        $trimmedCommand = trim($command);

        if ($trimmedCommand === '') {
            throw new RuntimeException('PowerShell command must not be empty.');
        }

        $launcherPath = $this->requireLauncherPath();
        $processCommand = [
            $this->executable,
            '-NoLogo',
            '-NonInteractive',
            '-File',
            $launcherPath,
            $trimmedCommand,
        ];

        Log::info('Executing PowerShell launcher command.', [
            'command' => $trimmedCommand,
            'timeout' => $timeout,
            'executable' => $this->executable,
            'launcher_path' => $launcherPath,
            'source' => $this->configurationSource,
            'site_path' => $this->siteConfigPath,
            'used_default_executable' => $this->usedDefaultExecutable,
        ]);

        return $this->executeCommand($processCommand, $timeout);
    }

    public function startScheduledTask(string $taskPath): ProcessResult
    {
        [$resolvedTaskPath, $resolvedTaskName] = $this->normalizeScheduledTaskPath($taskPath);
        $scheduledTaskCommand = "Start-ScheduledTask -TaskPath '"
            .$this->escapeForPowerShellSingleQuotes($resolvedTaskPath)
            ."' -TaskName '"
            .$this->escapeForPowerShellSingleQuotes($resolvedTaskName)
            ."'";
        $processCommand = [
            $this->executable,
            '-NoLogo',
            '-NonInteractive',
            '-Command',
            $scheduledTaskCommand,
        ];

        Log::info('Starting scheduled task via PowerShellService.', [
            'task_path' => $resolvedTaskPath,
            'task_name' => $resolvedTaskName,
            'executable' => $this->executable,
            'source' => $this->configurationSource,
            'site_path' => $this->siteConfigPath,
            'used_default_executable' => $this->usedDefaultExecutable,
        ]);

        return $this->executeCommand($processCommand);
    }

    protected function executeCommand(array $command, ?int $timeout = null): ProcessResult
    {
        $process = new Process($command, base_path());
        $process->setTimeout($timeout);
        $process->run();
        $exitCode = $process->getExitCode();

        if (! is_int($exitCode)) {
            $exitCode = -1;
        }

        $result = new ProcessResult($exitCode, $process->getOutput(), $process->getErrorOutput());

        Log::info('PowerShell command finished.', [
            'exit_code' => $result->exitCode,
            'stdout' => $result->stdout,
            'stderr' => $result->stderr,
        ]);

        return $result;
    }

    private function requireLauncherPath(): string
    {
        if (! is_string($this->launcherPath) || trim($this->launcherPath) === '') {
            Log::error('PowerShell launcher path is not configured.', [
                'source' => $this->configurationSource,
                'site_path' => $this->siteConfigPath,
                'used_default_executable' => $this->usedDefaultExecutable,
            ]);

            throw new RuntimeException('PowerShell launcher path must be configured before calling run().');
        }

        return $this->launcherPath;
    }

    /**
     * @return array{0: string, 1: string}
     */
    private function normalizeScheduledTaskPath(string $taskPath): array
    {
        $normalizedTaskPath = str_replace('/', '\\', trim($taskPath));
        $trimmedTaskPath = rtrim($normalizedTaskPath, '\\');

        if ($trimmedTaskPath === '') {
            throw new RuntimeException('Scheduled task path must include a task name.');
        }

        $lastSeparatorPosition = strrpos($trimmedTaskPath, '\\');

        if ($lastSeparatorPosition === false) {
            return ['\\', $trimmedTaskPath];
        }

        $resolvedTaskName = substr($trimmedTaskPath, $lastSeparatorPosition + 1);
        $resolvedTaskPath = substr($trimmedTaskPath, 0, $lastSeparatorPosition + 1);

        if (! is_string($resolvedTaskName) || $resolvedTaskName === '') {
            throw new RuntimeException('Scheduled task path must include a task name.');
        }

        if (! is_string($resolvedTaskPath) || $resolvedTaskPath === '') {
            $resolvedTaskPath = '\\';
        }

        return [$resolvedTaskPath, $resolvedTaskName];
    }

    private function escapeForPowerShellSingleQuotes(string $value): string
    {
        return str_replace("'", "''", $value);
    }
}