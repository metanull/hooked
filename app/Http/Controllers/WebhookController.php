<?php

namespace App\Http\Controllers;

use App\Jobs\DeploymentJob;
use App\Services\Webhooks\WebhookProviderManager;
use App\Services\Webhooks\WebhookTaskResolver;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use RuntimeException;

class WebhookController extends Controller
{
    public function __construct(
        private readonly WebhookProviderManager $providerManager,
        private readonly WebhookTaskResolver $taskResolver,
    ) {}

    public function store(Request $request, string $provider): JsonResponse
    {
        $webhookProvider = $this->providerManager->resolve($provider);

        if ($webhookProvider === null) {
            abort(404, 'Webhook provider was not found.');
        }

        if (! $webhookProvider->validateRequest($request)) {
            abort(403, 'Webhook request validation failed.');
        }

        try {
            $payload = $webhookProvider->parsePayload($request);
            $task = $this->taskResolver->resolve($payload);
        } catch (RuntimeException $exception) {
            return response()->json([
                'message' => $exception->getMessage(),
            ], 400);
        }

        DeploymentJob::dispatch($task->id);

        return response()->json([
            'status' => 'accepted',
            'provider' => $webhookProvider->getProviderName(),
            'task' => $task->name,
        ]);
    }
}