<?php

namespace App\Contracts;

use App\DataTransferObjects\WebhookPayload;
use Illuminate\Http\Request;

interface WebhookProviderInterface
{
    public function validateRequest(Request $request): bool;

    public function parsePayload(Request $request): WebhookPayload;

    public function getProviderName(): string;
}