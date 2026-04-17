<?php

use App\Services\Exhibitions\ExhibitionRegistrySyncService;
use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;

Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote');

Artisan::command('exhibitions:sync', function (ExhibitionRegistrySyncService $syncService) {
    $count = $syncService->sync();

    $this->info('Synchronized '.$count.' exhibition records from the registry.');
})->purpose('Synchronize exhibitions from the MWNF registry into SQLite.');
