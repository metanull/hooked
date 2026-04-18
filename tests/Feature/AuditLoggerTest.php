<?php

namespace Tests\Feature;

use App\Models\AuditLog;
use App\Models\User;
use App\Services\AuditLogger;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\Request;
use Tests\TestCase;

class AuditLoggerTest extends TestCase
{
    use RefreshDatabase;

    public function test_logger_persists_authenticated_user_ip_and_payload(): void
    {
        $user = User::factory()->create([
            'email' => 'auditor@example.test',
        ]);
        $request = Request::create('/admin/dashboard', 'GET', server: [
            'REMOTE_ADDR' => '10.20.30.40',
        ]);

        $this->actingAs($user);
        $this->app->instance('request', $request);
        $this->app->instance(Request::class, $request);

        app(AuditLogger::class)->log('task.triggered', 'books_client', [
            'triggered_by' => 'auditor@example.test',
        ]);

        $entry = AuditLog::query()->first();

        $this->assertInstanceOf(AuditLog::class, $entry);
        $this->assertSame('auditor@example.test', $entry->user);
        $this->assertSame('task.triggered', $entry->action);
        $this->assertSame('books_client', $entry->target);
        $this->assertSame(['triggered_by' => 'auditor@example.test'], $entry->payload);
        $this->assertSame('10.20.30.40', $entry->ip_address);
        $this->assertNotNull($entry->created_at);
    }

    public function test_logger_allows_guest_entries_for_webhook_style_events(): void
    {
        $request = Request::create('/webhook/bitbucket', 'POST', server: [
            'REMOTE_ADDR' => '192.168.1.50',
        ]);

        $this->app->instance('request', $request);
        $this->app->instance(Request::class, $request);

        app(AuditLogger::class)->log('webhook.received', 'bitbucket:main', [
            'provider' => 'bitbucket',
        ]);

        $this->assertDatabaseHas('audit_log', [
            'user' => null,
            'action' => 'webhook.received',
            'target' => 'bitbucket:main',
            'ip_address' => '192.168.1.50',
        ]);
    }
}