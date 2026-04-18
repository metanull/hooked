<?php

namespace App\Http\Controllers\Auth;

use App\Http\Controllers\Controller;
use App\Http\Requests\Auth\LoginRequest;
use App\Services\AuditLogger;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\View\View;

class AuthenticatedSessionController extends Controller
{
    /**
     * Display the login view.
     */
    public function create(): View
    {
        return view('auth.login');
    }

    /**
     * Handle an incoming authentication request.
     */
    public function store(LoginRequest $request, AuditLogger $auditLogger): RedirectResponse
    {
        $request->authenticate();

        $request->session()->regenerate();

        $auditLogger->log('auth.login', 'web', $this->resolveSessionPayload($request));

        return redirect()->intended(route('dashboard', absolute: false));
    }

    /**
     * Destroy an authenticated session.
     */
    public function destroy(Request $request, AuditLogger $auditLogger): RedirectResponse
    {
        $auditLogger->log('auth.logout', 'web', $this->resolveSessionPayload($request));

        Auth::guard('web')->logout();

        $request->session()->invalidate();

        $request->session()->regenerateToken();

        return redirect('/');
    }

    /**
     * @return array<string, string>
     */
    private function resolveSessionPayload(Request $request): array
    {
        $payload = [
            'guard' => 'web',
        ];
        $user = $request->user();

        if ($user === null) {
            return $payload;
        }

        $email = data_get($user, 'email');

        if (! is_string($email) || trim($email) === '') {
            return $payload;
        }

        $payload['email'] = trim($email);

        return $payload;
    }
}
