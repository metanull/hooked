<?php

namespace App\Services\Exhibitions;

use App\Models\Exhibition;
use App\Services\PowerShellService;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\Log;
use RuntimeException;

class ExhibitionQueueService
{
    public function __construct(
        private readonly PowerShellService $powerShellService,
    ) {}

    public function publishDemo(Exhibition $exhibition): void
    {
        $this->queueSingleCommand("Publish-MWNFExhibition -Name ''{$this->escapeCommandValue($exhibition->name)}'' -LanguageId ''{$this->escapeCommandValue($exhibition->language_id)}'' -Demo");
    }

    public function unpublishDemo(Exhibition $exhibition): void
    {
        $this->queueSingleCommand("Unpublish-MWNFExhibition -Name ''{$this->escapeCommandValue($exhibition->name)}'' -LanguageId ''{$this->escapeCommandValue($exhibition->language_id)}'' -Demo");
    }

    public function publishLive(Exhibition $exhibition): void
    {
        $this->queueSingleCommand("Publish-MWNFExhibition -Name ''{$this->escapeCommandValue($exhibition->name)}'' -LanguageId ''{$this->escapeCommandValue($exhibition->language_id)}''");
    }

    public function unpublishLive(Exhibition $exhibition): void
    {
        $this->queueSingleCommand("Unpublish-MWNFExhibition -Name ''{$this->escapeCommandValue($exhibition->name)}'' -LanguageId ''{$this->escapeCommandValue($exhibition->language_id)}''");
    }

    public function uninstall(Exhibition $exhibition): void
    {
        $this->queueSingleCommand("Uninstall-MWNFExhibition -Name ''{$this->escapeCommandValue($exhibition->name)}'' -LanguageId ''{$this->escapeCommandValue($exhibition->language_id)}''");
    }

    public function publishAll(Collection $exhibitions): void
    {
        foreach ($exhibitions as $exhibition) {
            if (! $exhibition instanceof Exhibition) {
                continue;
            }

            $this->runQueuePushCommand("Publish-MWNFExhibition -Name ''{$this->escapeCommandValue($exhibition->name)}'' -LanguageId ''{$this->escapeCommandValue($exhibition->language_id)}'' -Demo");

            if ($this->shouldSkipLivePublish($exhibition)) {
                Log::info('Skipped live publish for exhibition during publish all because the name matched the legacy skip rules.', [
                    'name' => $exhibition->name,
                    'language_id' => $exhibition->language_id,
                ]);

                continue;
            }

            $this->runQueuePushCommand("Publish-MWNFExhibition -Name ''{$this->escapeCommandValue($exhibition->name)}'' -LanguageId ''{$this->escapeCommandValue($exhibition->language_id)}''");
        }

        $this->startQueueRunner();
    }

    private function queueSingleCommand(string $innerCommand): void
    {
        $this->runQueuePushCommand($innerCommand);
        $this->startQueueRunner();
    }

    private function runQueuePushCommand(string $innerCommand): void
    {
        $command = "Push-MWNFQueue '{$innerCommand}' | ConvertTo-Json -Depth 10";
        $result = $this->powerShellService->run($command);

        if (! $result->successful()) {
            Log::error('Queue command failed.', [
                'command' => $command,
                'exit_code' => $result->exitCode,
                'stdout' => $result->stdout,
                'stderr' => $result->stderr,
            ]);

            throw new RuntimeException('Unable to queue the exhibition command.');
        }
    }

    private function startQueueRunner(): void
    {
        $result = $this->powerShellService->run('Start-MWNFQueueRunner');

        if (! $result->successful()) {
            Log::error('Starting the exhibition queue runner failed.', [
                'exit_code' => $result->exitCode,
                'stdout' => $result->stdout,
                'stderr' => $result->stderr,
            ]);

            throw new RuntimeException('Unable to start the exhibition queue runner.');
        }
    }

    private function shouldSkipLivePublish(Exhibition $exhibition): bool
    {
        return preg_match('/(demo|test|playground)/i', $exhibition->name) === 1;
    }

    private function escapeCommandValue(string $value): string
    {
        return str_replace("'", "''", $value);
    }
}