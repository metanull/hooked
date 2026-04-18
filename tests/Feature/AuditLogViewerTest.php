<?php

namespace Tests\Feature;

use App\Livewire\AuditLogViewer;
use App\Models\AuditLog;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Livewire\Livewire;
use Tests\TestCase;

class AuditLogViewerTest extends TestCase
{
    use RefreshDatabase;

    public function test_component_renders_entries_and_can_expand_payload(): void
    {
        $entry = AuditLog::query()->create([
            'user' => 'auditor@example.test',
            'action' => 'task.triggered',
            'target' => 'deploy-hooked',
            'payload' => [
                'triggered_by' => 'auditor@example.test',
                'source' => 'task_dashboard',
            ],
            'ip_address' => '10.1.2.3',
            'created_at' => now(),
        ]);

        Livewire::test(AuditLogViewer::class)
            ->assertSee('auditor@example.test')
            ->assertSee('task.triggered')
            ->assertSee('deploy-hooked')
            ->call('togglePayload', $entry->id)
            ->assertSee('triggered_by')
            ->assertSee('task_dashboard');
    }

    public function test_component_filters_entries_by_user_action_and_date(): void
    {
        AuditLog::query()->create([
            'user' => 'recent@example.test',
            'action' => 'auth.login',
            'target' => 'web',
            'payload' => ['guard' => 'web'],
            'ip_address' => '10.1.2.3',
            'created_at' => now()->subDay(),
        ]);
        AuditLog::query()->create([
            'user' => 'older@example.test',
            'action' => 'webhook.received',
            'target' => 'hooked:main',
            'payload' => ['provider' => 'bitbucket'],
            'ip_address' => '10.1.2.4',
            'created_at' => now()->subDays(8),
        ]);

        Livewire::test(AuditLogViewer::class)
            ->set('userFilter', 'recent@example.test')
            ->set('actionFilter', 'auth.login')
            ->set('dateFrom', now()->subDays(2)->format('Y-m-d'))
            ->set('dateTo', now()->format('Y-m-d'))
            ->assertSee('recent@example.test')
            ->assertDontSee('older@example.test')
            ->assertDontSee('hooked:main');
    }

    public function test_component_renders_guest_webhook_label_for_null_user(): void
    {
        AuditLog::query()->create([
            'user' => null,
            'action' => 'webhook.received',
            'target' => 'hooked:main',
            'payload' => ['provider' => 'bitbucket'],
            'ip_address' => '10.1.2.4',
            'created_at' => now(),
        ]);

        Livewire::test(AuditLogViewer::class)
            ->assertSee('Guest / webhook')
            ->assertSee('webhook.received');
    }
}