<?php

namespace App\Services\Exhibitions;

use App\Services\PowerShellService;
use Illuminate\Support\Facades\Log;
use RuntimeException;

class ExhibitionQueueStatusService
{
    public function __construct(
        private readonly PowerShellService $powerShellService,
    ) {}

    /**
     * @return array{state: string, busy: bool, pending_commands: array<int, array{id: string, command: string}>}
     */
    public function readState(): array
    {
        $stateResult = $this->powerShellService->run('Get-MWNFQueueRunnerState');

        if (! $stateResult->successful()) {
            Log::error('Reading the exhibition queue runner state failed.', [
                'exit_code' => $stateResult->exitCode,
                'stdout' => $stateResult->stdout,
                'stderr' => $stateResult->stderr,
            ]);

            throw new RuntimeException('Unable to read the exhibition queue runner state.');
        }

        $state = trim($stateResult->stdout);

        if ($state === '') {
            Log::error('Reading the exhibition queue runner state returned an empty response.');

            throw new RuntimeException('Exhibition queue runner state response was empty.');
        }

        $queueResult = $this->powerShellService->run('Get-MWNFQueue | ConvertTo-Json -Depth 10');

        if (! $queueResult->successful()) {
            Log::error('Reading the exhibition queue contents failed.', [
                'exit_code' => $queueResult->exitCode,
                'stdout' => $queueResult->stdout,
                'stderr' => $queueResult->stderr,
            ]);

            throw new RuntimeException('Unable to read the exhibition queue contents.');
        }

        return [
            'state' => $state,
            'busy' => $state !== 'Ready',
            'pending_commands' => $this->decodeQueuePayload($queueResult->stdout),
        ];
    }

    /**
     * @return array<int, array{id: string, command: string}>
     */
    private function decodeQueuePayload(string $stdout): array
    {
        $trimmedOutput = trim($stdout);

        if ($trimmedOutput === '') {
            return [];
        }

        $decoded = json_decode($trimmedOutput, true);

        if (! is_array($decoded)) {
            Log::error('The exhibition queue JSON payload did not decode to an array.', [
                'stdout' => $stdout,
            ]);

            throw new RuntimeException('Exhibition queue payload must decode to an array.');
        }

        if ($this->isAssociativeArray($decoded)) {
            $decoded = [$decoded];
        }

        $entries = [];

        foreach ($decoded as $entry) {
            if (! is_array($entry)) {
                Log::error('The exhibition queue JSON payload contained a non-array entry.', [
                    'entry' => $entry,
                ]);

                throw new RuntimeException('Each exhibition queue entry must decode to an array.');
            }

            if (! array_key_exists('Name', $entry) || ! is_scalar($entry['Name'])) {
                throw new RuntimeException('Each exhibition queue entry must include a Name value.');
            }

            if (! array_key_exists('Value', $entry) || ! is_scalar($entry['Value'])) {
                throw new RuntimeException('Each exhibition queue entry must include a Value value.');
            }

            $entries[] = [
                'id' => (string) $entry['Name'],
                'command' => (string) $entry['Value'],
            ];
        }

        return $entries;
    }

    /**
     * @param  array<mixed>  $value
     */
    private function isAssociativeArray(array $value): bool
    {
        return array_keys($value) !== range(0, count($value) - 1);
    }
}