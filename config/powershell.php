<?php

$siteConfigPath = config_path('site/powershell.php');
$siteConfiguration = [];
$configurationSource = 'env';

if (is_file($siteConfigPath)) {
    $siteConfiguration = require $siteConfigPath;

    if (! is_array($siteConfiguration)) {
        throw new \RuntimeException('The site PowerShell configuration must return an array.');
    }

    $configurationSource = 'site';
}

$executable = null;

if (array_key_exists('executable', $siteConfiguration) && is_string($siteConfiguration['executable'])) {
    $executable = trim($siteConfiguration['executable']);
}

if ($executable === null || $executable === '') {
    $environmentExecutable = env('POWERSHELL_EXECUTABLE');

    if (is_string($environmentExecutable) && trim($environmentExecutable) !== '') {
        $executable = trim($environmentExecutable);
    }
}

$usedDefaultExecutable = false;

if ($executable === null || $executable === '') {
    $executable = 'powershell';
    $usedDefaultExecutable = true;
}

$launcherPath = null;

if (array_key_exists('launcher_path', $siteConfiguration) && is_string($siteConfiguration['launcher_path']) && trim($siteConfiguration['launcher_path']) !== '') {
    $launcherPath = trim($siteConfiguration['launcher_path']);
}

if ($launcherPath === null) {
    $environmentLauncherPath = env('POWERSHELL_LAUNCHER_PATH');

    if (is_string($environmentLauncherPath) && trim($environmentLauncherPath) !== '') {
        $launcherPath = trim($environmentLauncherPath);
    }
}

return [
    'source' => $configurationSource,
    'site_path' => $siteConfigPath,
    'executable' => $executable,
    'launcher_path' => $launcherPath,
    'used_default_executable' => $usedDefaultExecutable,
];