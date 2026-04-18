<?php

$applicationRoot = env('APP_WEBROOT', 'C:/mwnf-server/apps');

$scheduledTaskDirectories = [
    'local' => '\\local.museumwnf.org\\',
    'www' => '\\www.museumwnf.org\\',
    'demo' => '\\upgrade.museumwnf.org\\',
    'dxa_api' => '\\www.museumwnf.org\\DXA-API\\',
    'dxa_cli' => '\\www.museumwnf.org\\DXA-CLI\\',
];

$tasks = [];

$makeTask = function (
    string $name,
    string $directory,
    string $label,
    string $scheduledTaskPath,
    ?string $repoPath = null,
    string $repoBranch = 'master',
    ?array $webhookMatch = null,
    bool $active = true,
) use (&$tasks): void {
    $task = [
        'directory' => $directory,
        'label' => $label,
        'scheduled_task_path' => $scheduledTaskPath,
        'type' => 'run',
        'active' => $active,
    ];

    if ($repoPath !== null) {
        $task['repo_path'] = $repoPath;
        $task['repo_branch'] = $repoBranch;
    }

    if ($webhookMatch !== null) {
        $task['webhook_match'] = $webhookMatch;
    }

    $tasks[$name] = $task;
};

$makeTask('data_add-uploaded-images', 'data', 'add-uploaded-images', $scheduledTaskDirectories['local'].'add-uploaded-images');
$makeTask('data_resize-images', 'data', 'resize-images', $scheduledTaskDirectories['local'].'resize-images');
$makeTask('data_glossary', 'data', 'glossary', $scheduledTaskDirectories['local'].'glossary');
$makeTask('data_api-cache', 'data', 'api-cache', $scheduledTaskDirectories['local'].'clear-api-cache');

$dxaClientTasks = [
    'amulets-client',
    'archaeology-client',
    'architectural-elements-client',
    'arms-armoury-client',
    'calligraphy-client',
    'carpets-client',
    'cars-client',
    'ceramics-client',
    'clothing-client',
    'coins-medals-client',
    'communication-client',
    'funerary-objects-client',
    'galleries-client',
    'gallery-partners-client',
    'glass-client',
    'gold-silver-client',
    'ivory-client',
    'jewellery-client',
    'landscapes-client',
    'leatherworks-client',
    'manuscripts-client',
    'metalwork-client',
    'mosaics-client',
    'musical-instruments-client',
    'paintings-client',
    'photographs-client',
    'porcelain-client',
    'portraits-client',
    'precious-stones-client',
    'prints-drawings-client',
    'religious-life-client',
    'scientific-objects-client',
    'sculptures-client',
    'textiles-client',
    'theatre-client',
    'toys-games-client',
    'unclear-doubts-excluded-client',
    'wallpaintings-client',
    'weights-measures-client',
    'woodwork-client',
];

foreach ($dxaClientTasks as $taskLabel) {
    $host = substr($taskLabel, 0, -7);
    $makeTask(
        'dxa_'.$taskLabel,
        'dxa',
        $taskLabel,
        $scheduledTaskDirectories['dxa_cli'].$taskLabel,
        $applicationRoot.'/'.$host.'.museumwnf.org/client'
    );
}

$dxaApiTasks = [
    'amulets-api',
    'archaeology-api',
    'architectural-elements-api',
    'arms-armoury-api',
    'calligraphy-api',
    'carpets-api',
    'cars-api',
    'ceramics-api',
    'clothing-api',
    'coins-medals-api',
    'communication-api',
    'funerary-objects-api',
    'galleries-api',
    'gallery-partners-api',
    'glass-api',
    'gold-silver-api',
    'ivory-api',
    'jewellery-api',
    'landscapes-api',
    'leatherworks-api',
    'manuscripts-api',
    'metalwork-api',
    'mosaics-api',
    'musical-instruments-api',
    'paintings-api',
    'photographs-api',
    'porcelain-api',
    'portraits-api',
    'precious-stones-api',
    'prints-drawings-api',
    'religious-life-api',
    'scientific-objects-api',
    'sculptures-api',
    'textiles-api',
    'theatre-api',
    'toys-games-api',
    'unclear-doubts-excluded-api',
    'wallpaintings-api',
    'weights-measures-api',
    'woodwork-api',
];

foreach ($dxaApiTasks as $taskLabel) {
    $host = substr($taskLabel, 0, -4);
    $makeTask(
        'dxa_'.$taskLabel,
        'dxa',
        $taskLabel,
        $scheduledTaskDirectories['dxa_api'].$taskLabel,
        $applicationRoot.'/'.$host.'.museumwnf.org/api'
    );
}

$makeTask('books_client', 'books', 'client', $scheduledTaskDirectories['www'].'books-client', $applicationRoot.'/books.museumwnf.org/client');
$makeTask('books_api', 'books', 'api', $scheduledTaskDirectories['www'].'books-api', $applicationRoot.'/books.museumwnf.org/api');

$makeTask('dynasties_client', 'dynasties', 'client', $scheduledTaskDirectories['www'].'dynasties-client', $applicationRoot.'/dynasties-local.museumwnf.org/client');
$makeTask('dynasties_api', 'dynasties', 'api', $scheduledTaskDirectories['www'].'dynasties-api', $applicationRoot.'/dynasties-local.museumwnf.org/api');

$makeTask('explore_client', 'explore', 'client', $scheduledTaskDirectories['www'].'explore-client', $applicationRoot.'/explore.museumwnf.org/client');
$makeTask('explore_api', 'explore', 'api', $scheduledTaskDirectories['www'].'explore-api', $applicationRoot.'/explore.museumwnf.org/api');

$makeTask('portal_client', 'portal', 'client', $scheduledTaskDirectories['www'].'portal-client', $applicationRoot.'/portal.museumwnf.org/client');
$makeTask('portal_api', 'portal', 'api', $scheduledTaskDirectories['www'].'portal-api', $applicationRoot.'/portal.museumwnf.org/api');
$makeTask('portal_old', 'portal', 'old', $scheduledTaskDirectories['www'].'www', $applicationRoot.'/museumwnf.org/app');

$makeTask('website_www', 'website', 'www', $scheduledTaskDirectories['www'].'www', $applicationRoot.'/museumwnf.org/app', 'master', ['repository' => 'museumwnf.org', 'branch' => 'master']);
$makeTask('website_islamicart', 'website', 'islamicart', $scheduledTaskDirectories['www'].'islamicart', $applicationRoot.'/islamicart.museumwnf.org/app', 'master', ['repository' => 'islamicart', 'branch' => 'master']);
$makeTask('website_baroqueart', 'website', 'baroqueart', $scheduledTaskDirectories['www'].'baroqueart', $applicationRoot.'/baroqueart.museumwnf.org/app', 'master', ['repository' => 'baroqueart', 'branch' => 'master']);
$makeTask('website_sharinghistory', 'website', 'sharinghistory', $scheduledTaskDirectories['www'].'sharinghistory', $applicationRoot.'/sharinghistory.museumwnf.org/app', 'master', ['repository' => 'sharinghistory', 'branch' => 'master']);
$makeTask('website_travels', 'website', 'travels', $scheduledTaskDirectories['www'].'travels', $applicationRoot.'/travels.museumwnf.org/app', 'master', ['repository' => 'travels', 'branch' => 'master']);

$makeTask('local_virtual-office', 'local', 'virtual-office', $scheduledTaskDirectories['local'].'virtual-office', $applicationRoot.'/virtual-office.museumwnf.org/app', 'master', ['repository' => 'virtual-office', 'branch' => 'master']);
$makeTask('local_images', 'local', 'images', $scheduledTaskDirectories['local'].'images', $applicationRoot.'/images.museumwnf.org/app', 'master', ['repository' => 'images', 'branch' => 'master']);
$makeTask('local_webhook', 'local', 'webhook', $scheduledTaskDirectories['local'].'webhook', $applicationRoot.'/upgrade.museumwnf.org/app/webhook', 'main', ['repository' => 'hooked', 'branch' => 'main']);
$makeTask('local_atlassian', 'local', 'atlassian', $scheduledTaskDirectories['local'].'atlassian', $applicationRoot.'/upgrade.museumwnf.org/app/atlassian', 'master', ['repository' => 'atlassian', 'branch' => 'master']);
$makeTask('local_logviewer', 'local', 'logviewer', $scheduledTaskDirectories['local'].'logviewer', $applicationRoot.'/logviewer.museumwnf.org/app', 'master', ['repository' => 'logviewer', 'branch' => 'master']);

$makeTask('database_creation', 'database', 'creation', $scheduledTaskDirectories['local'].'database-creation');
$makeTask('database_content', 'database', 'content', $scheduledTaskDirectories['local'].'database-content');

$makeTask('demo_books-client', 'demo', 'books-client', $scheduledTaskDirectories['demo'].'upgrade-books-client', $applicationRoot.'/upgrade-books.museumwnf.org/client', 'develop');
$makeTask('demo_books-api', 'demo', 'books-api', $scheduledTaskDirectories['demo'].'upgrade-books-api', $applicationRoot.'/upgrade-books.museumwnf.org/api', 'develop');
$makeTask('demo_portal-client', 'demo', 'portal-client', $scheduledTaskDirectories['demo'].'portal-client', $applicationRoot.'/upgrade-portal.museumwnf.org/client', 'develop');
$makeTask('demo_portal-api', 'demo', 'portal-api', $scheduledTaskDirectories['demo'].'portal-api', $applicationRoot.'/upgrade-portal.museumwnf.org/api', 'develop');
$makeTask('demo_explore-client', 'demo', 'explore-client', $scheduledTaskDirectories['demo'].'explore-client', $applicationRoot.'/upgrade-explore.museumwnf.org/client', 'develop');
$makeTask('demo_explore-api', 'demo', 'explore-api', $scheduledTaskDirectories['demo'].'explore-api', $applicationRoot.'/upgrade-explore.museumwnf.org/api', 'develop');
$makeTask('demo_galleries-client', 'demo', 'galleries-client', $scheduledTaskDirectories['demo'].'galleries-client', $applicationRoot.'/upgrade-galleries.museumwnf.org/client', 'develop');
$makeTask('demo_galleries-api', 'demo', 'galleries-api', $scheduledTaskDirectories['demo'].'galleries-api', $applicationRoot.'/upgrade-galleries.museumwnf.org/api', 'develop');
$makeTask('demo_islamicart', 'demo', 'islamicart', $scheduledTaskDirectories['demo'].'upgrade-dia', $applicationRoot.'/upgrade-dia.museumwnf.org/app', 'develop');
$makeTask('demo_dynasties-client', 'demo', 'dynasties-client', $scheduledTaskDirectories['demo'].'upgrade-dynasties-client', $applicationRoot.'/upgrade-dynasties-local.museumwnf.org/client', 'develop');
$makeTask('demo_dynasties-api', 'demo', 'dynasties-api', $scheduledTaskDirectories['demo'].'upgrade-dynasties-api', $applicationRoot.'/upgrade-dynasties-local.museumwnf.org/api', 'develop');

return $tasks;