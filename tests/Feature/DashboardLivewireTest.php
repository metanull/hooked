<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class DashboardLivewireTest extends TestCase
{
    use RefreshDatabase;

    public function test_dashboard_renders_the_livewire_status_panel(): void
    {
        $user = User::factory()->create();

        $response = $this
            ->actingAs($user)
            ->get('/admin/dashboard');

        $response->assertOk();
        $response->assertSee('Livewire component is ready.');
    }
}