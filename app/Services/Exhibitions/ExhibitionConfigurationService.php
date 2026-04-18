<?php

namespace App\Services\Exhibitions;

use App\Services\PowerShellService;
use Illuminate\Support\Facades\Log;
use RuntimeException;

class ExhibitionConfigurationService
{
    public function __construct(
        private readonly PowerShellService $powerShellService,
    ) {}

    public function install(string $name, string $languageId, string $apiEnvironment, string $clientEnvironment): void
    {
        $command = $this->buildInstallCommand($name, $languageId, $apiEnvironment, $clientEnvironment);
        $result = $this->powerShellService->run($command);

        if (! $result->successful()) {
            Log::error('Exhibition configuration save failed.', [
                'name' => $name,
                'language_id' => $languageId,
                'exit_code' => $result->exitCode,
                'stdout' => $result->stdout,
                'stderr' => $result->stderr,
            ]);

            throw new RuntimeException('Unable to save the exhibition configuration.');
        }
    }

    private function buildInstallCommand(string $name, string $languageId, string $apiEnvironment, string $clientEnvironment): string
    {
        $apiArguments = $this->buildArrayArgument($this->parseEnvironmentLines($apiEnvironment));
        $clientArguments = $this->buildArrayArgument($this->parseEnvironmentLines($clientEnvironment));

        return "Install-MWNFExhibition -Name '"
            .$this->escapeForPowerShellSingleQuotes($name)
            ."' -LanguageId '"
            .$this->escapeForPowerShellSingleQuotes($languageId)
            ."' -ApiEnvironment "
            .$apiArguments
            ." -ClientEnvironment "
            .$clientArguments
            .' | ConvertTo-Json -Depth 10';
    }

    /**
     * @return array<int, string>
     */
    private function parseEnvironmentLines(string $environment): array
    {
        $lines = preg_split('/\r\n|\r|\n/', $environment);

        if (! is_array($lines)) {
            return [];
        }

        $normalized = [];

        foreach ($lines as $line) {
            if (! is_string($line)) {
                continue;
            }

            $trimmedLine = trim($line);

            if ($trimmedLine !== '') {
                $normalized[] = $trimmedLine;
            }
        }

        return $normalized;
    }

    /**
     * @param  array<int, string>  $items
     */
    private function buildArrayArgument(array $items): string
    {
        $quotedItems = [];

        foreach ($items as $item) {
            $quotedItems[] = "'".$this->escapeForPowerShellSingleQuotes($item)."'";
        }

        return '@('.implode(',', $quotedItems).')';
    }

    private function escapeForPowerShellSingleQuotes(string $value): string
    {
        return str_replace("'", "''", $value);
    }
}