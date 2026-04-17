<?php

$siteConfigPath = config_path('site/ip-whitelist.php');
$siteConfiguration = [];
$configurationSource = 'env';

if (is_file($siteConfigPath)) {
    $siteConfiguration = require $siteConfigPath;

    if (! is_array($siteConfiguration)) {
        throw new \RuntimeException('The site IP whitelist configuration must return an array.');
    }

    $configurationSource = 'site';
}

$enabled = null;

if (array_key_exists('enabled', $siteConfiguration)) {
    $enabled = (bool) $siteConfiguration['enabled'];
}

if ($enabled === null) {
    $enabled = env('IP_WHITELIST_ENABLED', false);
}

$addresses = null;

if (array_key_exists('addresses', $siteConfiguration)) {
    $addresses = $siteConfiguration['addresses'];
}

if ($addresses === null) {
    $addresses = env('IP_WHITELIST_ADDRESSES');
}

if ($addresses === null) {
    $addresses = '';
}

return [
    'source' => $configurationSource,
    'site_path' => $siteConfigPath,
    'enabled' => (bool) $enabled,
    'addresses' => $addresses,
];