<?php

$taskDirectories = [
    'local' => '\\local.museumwnf.org\\',
    'www' => '\\www.museumwnf.org\\',
    'demo' => '\\upgrade.museumwnf.org\\',
    'dxa_api' => '\\www.museumwnf.org\\DXA-API\\',
    'dxa_cli' => '\\www.museumwnf.org\\DXA-CLI\\',
];

return [
    'data_add-uploaded-images' => [
        'directory' => 'local.museumwnf.org',
        'scheduled_task_path' => $taskDirectories['local'].'add-uploaded-images',
        'type' => 'run',
        'webhook_match' => null,
    ],
    'data_resize-images' => [
        'directory' => 'local.museumwnf.org',
        'scheduled_task_path' => $taskDirectories['local'].'resize-images',
        'type' => 'run',
        'webhook_match' => null,
    ],
    'data_glossary' => [
        'directory' => 'local.museumwnf.org',
        'scheduled_task_path' => $taskDirectories['local'].'glossary',
        'type' => 'run',
        'webhook_match' => null,
    ],
    'data_api-cache' => [
        'directory' => 'local.museumwnf.org',
        'scheduled_task_path' => $taskDirectories['local'].'clear-api-cache',
        'type' => 'run',
        'webhook_match' => null,
    ],
    'dxa_galleries-client' => [
        'directory' => 'www.museumwnf.org/DXA-CLI',
        'scheduled_task_path' => $taskDirectories['dxa_cli'].'galleries-client',
        'type' => 'run',
        'webhook_match' => [
            'repository' => 'galleries-client',
            'branch' => 'master',
        ],
    ],
    'dxa_galleries-api' => [
        'directory' => 'www.museumwnf.org/DXA-API',
        'scheduled_task_path' => $taskDirectories['dxa_api'].'galleries-api',
        'type' => 'run',
        'webhook_match' => [
            'repository' => 'galleries-api',
            'branch' => 'master',
        ],
    ],
    'dynasties_client' => [
        'directory' => 'www.museumwnf.org',
        'scheduled_task_path' => $taskDirectories['www'].'dynasties-client',
        'type' => 'run',
        'webhook_match' => [
            'repository' => 'dynasties-client',
            'branch' => 'master',
        ],
    ],
    'dynasties_api' => [
        'directory' => 'www.museumwnf.org',
        'scheduled_task_path' => $taskDirectories['www'].'dynasties-api',
        'type' => 'run',
        'webhook_match' => [
            'repository' => 'dynasties-api',
            'branch' => 'master',
        ],
    ],
    'explore_client' => [
        'directory' => 'www.museumwnf.org',
        'scheduled_task_path' => $taskDirectories['www'].'explore-client',
        'type' => 'run',
        'webhook_match' => [
            'repository' => 'explore-client',
            'branch' => 'master',
        ],
    ],
    'explore_api' => [
        'directory' => 'www.museumwnf.org',
        'scheduled_task_path' => $taskDirectories['www'].'explore-api',
        'type' => 'run',
        'webhook_match' => [
            'repository' => 'explore-api',
            'branch' => 'master',
        ],
    ],
    'books_client' => [
        'directory' => 'www.museumwnf.org',
        'scheduled_task_path' => $taskDirectories['www'].'books-client',
        'type' => 'run',
        'webhook_match' => [
            'repository' => 'books-client',
            'branch' => 'master',
        ],
    ],
    'books_api' => [
        'directory' => 'www.museumwnf.org',
        'scheduled_task_path' => $taskDirectories['www'].'books-api',
        'type' => 'run',
        'webhook_match' => [
            'repository' => 'books-api',
            'branch' => 'master',
        ],
    ],
    'portal_client' => [
        'directory' => 'www.museumwnf.org',
        'scheduled_task_path' => $taskDirectories['www'].'portal-client',
        'type' => 'run',
        'webhook_match' => [
            'repository' => 'portal-client',
            'branch' => 'master',
        ],
    ],
    'portal_api' => [
        'directory' => 'www.museumwnf.org',
        'scheduled_task_path' => $taskDirectories['www'].'portal-api',
        'type' => 'run',
        'webhook_match' => [
            'repository' => 'portal-api',
            'branch' => 'master',
        ],
    ],
    'portal_old' => [
        'directory' => 'www.museumwnf.org',
        'scheduled_task_path' => $taskDirectories['www'].'www',
        'type' => 'run',
        'webhook_match' => null,
    ],
    'website_www' => [
        'directory' => 'www.museumwnf.org',
        'scheduled_task_path' => $taskDirectories['www'].'www',
        'type' => 'run',
        'webhook_match' => [
            'repository' => 'museumwnf.org',
            'branch' => 'master',
        ],
    ],
    'website_islamicart' => [
        'directory' => 'www.museumwnf.org',
        'scheduled_task_path' => $taskDirectories['www'].'islamicart',
        'type' => 'run',
        'webhook_match' => [
            'repository' => 'islamicart',
            'branch' => 'master',
        ],
    ],
    'website_baroqueart' => [
        'directory' => 'www.museumwnf.org',
        'scheduled_task_path' => $taskDirectories['www'].'baroqueart',
        'type' => 'run',
        'webhook_match' => [
            'repository' => 'baroqueart',
            'branch' => 'master',
        ],
    ],
    'website_sharinghistory' => [
        'directory' => 'www.museumwnf.org',
        'scheduled_task_path' => $taskDirectories['www'].'sharinghistory',
        'type' => 'run',
        'webhook_match' => [
            'repository' => 'sharinghistory',
            'branch' => 'master',
        ],
    ],
    'website_travels' => [
        'directory' => 'www.museumwnf.org',
        'scheduled_task_path' => $taskDirectories['www'].'travels',
        'type' => 'run',
        'webhook_match' => [
            'repository' => 'travels',
            'branch' => 'master',
        ],
    ],
    'local_virtual-office' => [
        'directory' => 'local.museumwnf.org',
        'scheduled_task_path' => $taskDirectories['local'].'virtual-office',
        'type' => 'run',
        'webhook_match' => [
            'repository' => 'virtual-office',
            'branch' => 'master',
        ],
    ],
    'local_images' => [
        'directory' => 'local.museumwnf.org',
        'scheduled_task_path' => $taskDirectories['local'].'images',
        'type' => 'run',
        'webhook_match' => [
            'repository' => 'images',
            'branch' => 'master',
        ],
    ],
    'local_webhook' => [
        'directory' => 'local.museumwnf.org',
        'scheduled_task_path' => $taskDirectories['local'].'webhook',
        'type' => 'run',
        'webhook_match' => [
            'repository' => 'hooked',
            'branch' => 'main',
        ],
    ],
    'local_atlassian' => [
        'directory' => 'local.museumwnf.org',
        'scheduled_task_path' => $taskDirectories['local'].'atlassian',
        'type' => 'run',
        'webhook_match' => [
            'repository' => 'atlassian',
            'branch' => 'master',
        ],
    ],
    'local_logviewer' => [
        'directory' => 'local.museumwnf.org',
        'scheduled_task_path' => $taskDirectories['local'].'logviewer',
        'type' => 'run',
        'webhook_match' => [
            'repository' => 'logviewer',
            'branch' => 'master',
        ],
    ],
    'demo_book-client' => [
        'directory' => 'upgrade.museumwnf.org',
        'scheduled_task_path' => $taskDirectories['demo'].'upgrade-books-client',
        'type' => 'run',
        'webhook_match' => [
            'repository' => 'books-client',
            'branch' => 'develop',
        ],
    ],
    'demo_book-api' => [
        'directory' => 'upgrade.museumwnf.org',
        'scheduled_task_path' => $taskDirectories['demo'].'upgrade-books-api',
        'type' => 'run',
        'webhook_match' => [
            'repository' => 'books-api',
            'branch' => 'develop',
        ],
    ],
    'demo_portal-client' => [
        'directory' => 'upgrade.museumwnf.org',
        'scheduled_task_path' => $taskDirectories['demo'].'portal-client',
        'type' => 'run',
        'webhook_match' => [
            'repository' => 'portal-client',
            'branch' => 'develop',
        ],
    ],
    'demo_portal-api' => [
        'directory' => 'upgrade.museumwnf.org',
        'scheduled_task_path' => $taskDirectories['demo'].'portal-api',
        'type' => 'run',
        'webhook_match' => [
            'repository' => 'portal-api',
            'branch' => 'develop',
        ],
    ],
    'demo_explore-client' => [
        'directory' => 'upgrade.museumwnf.org',
        'scheduled_task_path' => $taskDirectories['demo'].'explore-client',
        'type' => 'run',
        'webhook_match' => [
            'repository' => 'explore-client',
            'branch' => 'develop',
        ],
    ],
    'demo_explore-api' => [
        'directory' => 'upgrade.museumwnf.org',
        'scheduled_task_path' => $taskDirectories['demo'].'explore-api',
        'type' => 'run',
        'webhook_match' => [
            'repository' => 'explore-api',
            'branch' => 'develop',
        ],
    ],
    'demo_galleries-client' => [
        'directory' => 'upgrade.museumwnf.org',
        'scheduled_task_path' => $taskDirectories['demo'].'galleries-client',
        'type' => 'run',
        'webhook_match' => [
            'repository' => 'galleries-client',
            'branch' => 'develop',
        ],
    ],
    'demo_galleries-api' => [
        'directory' => 'upgrade.museumwnf.org',
        'scheduled_task_path' => $taskDirectories['demo'].'galleries-api',
        'type' => 'run',
        'webhook_match' => [
            'repository' => 'galleries-api',
            'branch' => 'develop',
        ],
    ],
    'demo_website_islamicart' => [
        'directory' => 'upgrade.museumwnf.org',
        'scheduled_task_path' => $taskDirectories['demo'].'upgrade-dia',
        'type' => 'run',
        'webhook_match' => [
            'repository' => 'islamicart',
            'branch' => 'develop',
        ],
    ],
    'demo_dynasties_client' => [
        'directory' => 'upgrade.museumwnf.org',
        'scheduled_task_path' => $taskDirectories['demo'].'upgrade-dynasties-client',
        'type' => 'run',
        'webhook_match' => [
            'repository' => 'dynasties-client',
            'branch' => 'develop',
        ],
    ],
    'demo_dynasties_api' => [
        'directory' => 'upgrade.museumwnf.org',
        'scheduled_task_path' => $taskDirectories['demo'].'upgrade-dynasties-api',
        'type' => 'run',
        'webhook_match' => [
            'repository' => 'dynasties-api',
            'branch' => 'develop',
        ],
    ],
    'database_creation' => [
        'directory' => 'local.museumwnf.org',
        'scheduled_task_path' => $taskDirectories['local'].'database-creation',
        'type' => 'run',
        'webhook_match' => null,
    ],
    'database_content' => [
        'directory' => 'local.museumwnf.org',
        'scheduled_task_path' => $taskDirectories['local'].'database-content',
        'type' => 'run',
        'webhook_match' => null,
    ],
];