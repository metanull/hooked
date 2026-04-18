<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class DashboardLivewireTest extends TestCase
{
    use RefreshDatabase;

    public function test_dashboard_renders_the_task_and_deployment_livewire_components(): void
    {
        $user = User::factory()->create();

        $response = $this
            ->actingAs($user)
            ->get('/admin/dashboard');

        $response->assertOk();
        $response->assertSeeLivewire('task-dashboard');
        $response->assertSeeLivewire('deployment-history-viewer');
    }
}