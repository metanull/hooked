<?php

namespace Tests\Unit;

use App\Services\PowerShellService;
use App\Services\ProcessResult;
use RuntimeException;
use Tests\TestCase;

class PowerShellServiceTest extends TestCase
{
    public function test_run_uses_the_launcher_script_and_returns_a_process_result(): void
    {
        $service = new class ('pwsh', 'C:\\mwnf\\Launcher.ps1', 'env', base_path('config/site/powershell.php'), false) extends PowerShellService {
            /**
             * @var array<int, string>
             */
            public array $capturedCommand = [];

            public ?int $capturedTimeout = null;

            protected function executeCommand(array $command, ?int $timeout = null): ProcessResult
            {
                $this->capturedCommand = $command;
                $this->capturedTimeout = $timeout;

                return new ProcessResult(0, 'stdout', '');
            }
        };

        $result = $service->run("Write-Output 'ready'", 15);

        $this->assertTrue($result->successful());
        $this->assertSame('stdout', $result->stdout);
        $this->assertSame([
            'pwsh',
            '-NoLogo',
            '-NonInteractive',
            '-File',
            'C:\\mwnf\\Launcher.ps1',
            "Write-Output 'ready'",
        ], $service->capturedCommand);
        $this->assertSame(15, $service->capturedTimeout);
    }

    public function test_run_requires_a_launcher_path(): void
    {
        $service = new PowerShellService('powershell', null, 'env', base_path('config/site/powershell.php'), false);

        $this->expectException(RuntimeException::class);
        $this->expectExceptionMessage('PowerShell launcher path must be configured before calling run().');

        $service->run('Write-Output test');
    }

    public function test_start_scheduled_task_builds_the_expected_powershell_command(): void
    {
        $service = new class ('powershell', null, 'env', base_path('config/site/powershell.php'), false) extends PowerShellService {
            /**
             * @var array<int, string>
             */
            public array $capturedCommand = [];

            protected function executeCommand(array $command, ?int $timeout = null): ProcessResult
            {
                $this->capturedCommand = $command;

                return new ProcessResult(0, '', '');
            }
        };

        $result = $service->startScheduledTask('\\MWNF\\RunQueue');

        $this->assertTrue($result->successful());
        $this->assertSame([
            'powershell',
            '-NoLogo',
            '-NonInteractive',
            '-Command',
            "Start-ScheduledTask -TaskPath '\\MWNF\\' -TaskName 'RunQueue'",
        ], $service->capturedCommand);
    }
}