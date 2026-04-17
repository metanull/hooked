<?php

$siteConfigPath = config_path('site/proxy.php');
$siteConfiguration = [];
$configurationSource = 'env';

if (is_file($siteConfigPath)) {
    $siteConfiguration = require $siteConfigPath;

    if (! is_array($siteConfiguration)) {
        throw new \RuntimeException('The site proxy configuration must return an array.');
    }

    $configurationSource = 'site';
}

$proxyValues = null;

if (array_key_exists('proxies', $siteConfiguration)) {
    $proxyValues = $siteConfiguration['proxies'];
}

if ($proxyValues === null) {
    $proxyValues = env('TRUSTED_PROXY_IPS');
}

$headerValues = null;

if (array_key_exists('headers', $siteConfiguration)) {
    $headerValues = $siteConfiguration['headers'];
}

if ($headerValues === null) {
    $headerValues = env('TRUSTED_PROXY_HEADERS');
}

if ($headerValues === null) {
    $headerValues = 'X-Forwarded-For,X-Forwarded-Proto';
}

return [
    'source' => $configurationSource,
    'site_path' => $siteConfigPath,
    'proxies' => $proxyValues,
    'headers' => $headerValues,
];