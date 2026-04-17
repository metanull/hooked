<?php

namespace App\Contracts;

interface TrustedWebhookIpRangeProviderInterface
{
    /**
     * @return array<int, string>
     */
    public function getRanges(): array;
}