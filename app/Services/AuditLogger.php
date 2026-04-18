<?php

namespace App\Services;

use App\Models\AuditLog;
use Illuminate\Contracts\Auth\Factory as AuthFactory;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class AuditLogger
{
    public function __construct(
        private readonly AuthFactory $authFactory,
        private readonly Request $request,
    ) {}

    public function log(string $action, string $target, ?array $payload = null): void
    {
        AuditLog::query()->create([
            'user' => $this->resolveAuthenticatedUser(),
            'action' => $action,
            'target' => $target,
            'payload' => $payload,
            'ip_address' => $this->resolveIpAddress(),
            'created_at' => now(),
        ]);
    }

    private function resolveAuthenticatedUser(): ?string
    {
        $user = $this->authFactory->guard()->user();

        if ($user === null) {
            return null;
        }

        $email = data_get($user, 'email');

        if (! is_string($email) || trim($email) === '') {
            Log::warning('Audit logger could not resolve an email address for the authenticated user.', [
                'auth_identifier' => $user->getAuthIdentifier(),
                'auth_provider' => get_class($user),
            ]);

            return null;
        }

        return trim($email);
    }

    private function resolveIpAddress(): ?string
    {
        $ipAddress = $this->request->ip();

        if (! is_string($ipAddress) || trim($ipAddress) === '') {
            return null;
        }

        return trim($ipAddress);
    }
}