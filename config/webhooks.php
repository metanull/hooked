<?php

return [
    'providers' => [
        'bitbucket' => [
            'user_agent' => env('BITBUCKET_WEBHOOK_USER_AGENT', 'Bitbucket-Webhooks/2.0'),
            'shared_secret' => env('BITBUCKET_WEBHOOK_SECRET'),
        ],
    ],
    'atlassian' => [
        'ip_ranges_url' => env('ATLASSIAN_IP_RANGES_URL', 'https://ip-ranges.atlassian.com/'),
        'cache_key' => env('ATLASSIAN_IP_RANGES_CACHE_KEY', 'webhooks.atlassian_ip_ranges'),
        'cache_ttl_seconds' => 86400,
    ],
    'task_registry' => [],
];