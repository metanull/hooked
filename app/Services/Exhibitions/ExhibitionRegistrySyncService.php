<?php

namespace App\Services\Exhibitions;

use App\Models\Exhibition;
use App\Services\PowerShellService;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Validator;
use RuntimeException;

class ExhibitionRegistrySyncService
{
    public function __construct(
        private readonly PowerShellService $powerShellService,
    ) {}

    public function sync(): int
    {
        $result = $this->powerShellService->run('Get-MWNFExhibition | ConvertTo-Json -Depth 10');

        if (! $result->successful()) {
            Log::error('Exhibition registry sync failed because the PowerShell command returned a non-zero exit code.', [
                'exit_code' => $result->exitCode,
                'stderr' => $result->stderr,
                'stdout' => $result->stdout,
            ]);

            throw new RuntimeException('Unable to synchronize exhibitions from the registry.');
        }

        $records = $this->decodeRegistryPayload($result->stdout);
        $syncedAt = now();
        $count = 0;

        foreach ($records as $index => $record) {
            $payload = $this->mapRegistryRecord($record, $syncedAt, $index);
            Exhibition::query()->updateOrCreate(
                [
                    'name' => $payload['name'],
                    'language_id' => $payload['language_id'],
                ],
                $payload,
            );
            $count++;
        }

        Log::info('Exhibition registry sync completed.', [
            'count' => $count,
            'synced_at' => $syncedAt->toIso8601String(),
        ]);

        return $count;
    }

    /**
     * @return array<int, array<string, mixed>>
     */
    private function decodeRegistryPayload(string $stdout): array
    {
        $trimmedOutput = trim($stdout);

        if ($trimmedOutput === '') {
            Log::info('Exhibition registry sync returned an empty payload.');

            return [];
        }

        $decoded = json_decode($trimmedOutput, true);

        if (! is_array($decoded)) {
            Log::error('Exhibition registry sync returned JSON that did not decode to an array or record.', [
                'stdout' => $stdout,
            ]);

            throw new RuntimeException('Exhibition registry payload must decode to an array.');
        }

        if ($this->isAssociativeArray($decoded)) {
            return [$decoded];
        }

        foreach ($decoded as $record) {
            if (! is_array($record)) {
                Log::error('Exhibition registry sync returned a record that was not an array.', [
                    'record' => $record,
                ]);

                throw new RuntimeException('Each exhibition registry record must decode to an array.');
            }
        }

        return $decoded;
    }

    /**
     * @param  array<string, mixed>  $record
     * @return array<string, mixed>
     */
    private function mapRegistryRecord(array $record, \Illuminate\Support\Carbon $syncedAt, int $index): array
    {
        $name = $this->requireString($record, 'Name', $index);
        $languageId = $this->requireString($record, 'LanguageId', $index);
        $status = $this->requireString($record, 'Status', $index);
        $apiEnvironment = $this->normalizeEnvironmentPayload($record, 'ApiEnvironment', $index);
        $clientEnvironment = $this->normalizeEnvironmentPayload($record, 'ClientEnvironment', $index);

        $payload = [
            'name' => $name,
            'language_id' => $languageId,
            'status' => $status,
            'api_env' => $apiEnvironment,
            'client_env' => $clientEnvironment,
            'synced_at' => $syncedAt,
        ];

        $validator = Validator::make($payload, Exhibition::validationRules());

        if ($validator->fails()) {
            Log::error('Exhibition registry sync rejected a record because validation failed.', [
                'index' => $index,
                'errors' => $validator->errors()->all(),
                'payload' => $payload,
            ]);

            throw new RuntimeException('Exhibition registry record validation failed.');
        }

        return $payload;
    }

    /**
     * @param  array<string, mixed>  $record
     * @return array<string, string>|null
     */
    private function normalizeEnvironmentPayload(array $record, string $key, int $index): ?array
    {
        if (! array_key_exists($key, $record) || $record[$key] === null) {
            return null;
        }

        if (! is_array($record[$key])) {
            Log::error('Exhibition registry sync rejected a record because an environment payload was not an object or array.', [
                'index' => $index,
                'key' => $key,
                'value' => $record[$key],
            ]);

            throw new RuntimeException('Exhibition environment payload must decode to an array.');
        }

        $normalized = [];

        foreach ($record[$key] as $envKey => $envValue) {
            if (! is_string($envKey) || trim($envKey) === '') {
                Log::error('Exhibition registry sync rejected a record because an environment key was invalid.', [
                    'index' => $index,
                    'key' => $key,
                    'env_key' => $envKey,
                ]);

                throw new RuntimeException('Exhibition environment keys must be non-empty strings.');
            }

            if (is_string($envValue) || is_numeric($envValue) || is_bool($envValue)) {
                $normalized[trim($envKey)] = (string) $envValue;

                continue;
            }

            if ($envValue === null) {
                Log::info('Exhibition registry sync converted a null environment value to an empty string.', [
                    'index' => $index,
                    'key' => $key,
                    'env_key' => $envKey,
                ]);

                $normalized[trim($envKey)] = '';

                continue;
            }

            Log::error('Exhibition registry sync rejected a record because an environment value was not scalar.', [
                'index' => $index,
                'key' => $key,
                'env_key' => $envKey,
                'env_value' => $envValue,
            ]);

            throw new RuntimeException('Exhibition environment values must be scalar or null.');
        }

        return $normalized;
    }

    /**
     * @param  array<string, mixed>  $record
     */
    private function requireString(array $record, string $key, int $index): string
    {
        if (! array_key_exists($key, $record) || ! is_string($record[$key])) {
            Log::error('Exhibition registry sync rejected a record because a required field was missing.', [
                'index' => $index,
                'field' => $key,
                'record' => $record,
            ]);

            throw new RuntimeException('Exhibition registry record is missing a required string field.');
        }

        $value = trim($record[$key]);

        if ($value === '') {
            Log::error('Exhibition registry sync rejected a record because a required field was empty.', [
                'index' => $index,
                'field' => $key,
            ]);

            throw new RuntimeException('Exhibition registry record contains an empty required field.');
        }

        return $value;
    }

    /**
     * @param  array<mixed>  $value
     */
    private function isAssociativeArray(array $value): bool
    {
        return array_keys($value) !== range(0, count($value) - 1);
    }
}