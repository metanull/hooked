<?php

namespace App\Livewire;

use App\Models\AuditLog;
use Illuminate\Contracts\View\View;
use Illuminate\Support\Facades\Log;
use Livewire\Component;

class AuditLogViewer extends Component
{
    public string $userFilter = '';

    public string $actionFilter = '';

    public string $dateFrom = '';

    public string $dateTo = '';

    /**
     * @var array<int, int>
     */
    public array $expandedEntries = [];

    public function render(): View
    {
        $query = AuditLog::query()->orderByDesc('created_at')->orderByDesc('id');

        if ($this->userFilter !== '') {
            $query->where('user', 'like', '%'.$this->userFilter.'%');
        }

        if ($this->actionFilter !== '') {
            $query->where('action', $this->actionFilter);
        }

        if ($this->dateFrom !== '') {
            $query->whereDate('created_at', '>=', $this->dateFrom);
        }

        if ($this->dateTo !== '') {
            $query->whereDate('created_at', '<=', $this->dateTo);
        }

        return view('livewire.audit-log-viewer', [
            'auditEntries' => $query->get(),
            'availableActions' => AuditLog::query()->distinct()->orderBy('action')->pluck('action'),
        ]);
    }

    public function togglePayload(int $auditLogId): void
    {
        if (in_array($auditLogId, $this->expandedEntries, true)) {
            $this->expandedEntries = array_values(array_filter(
                $this->expandedEntries,
                fn (int $expandedEntryId): bool => $expandedEntryId !== $auditLogId,
            ));

            return;
        }

        $this->expandedEntries[] = $auditLogId;
    }

    public function isExpanded(int $auditLogId): bool
    {
        return in_array($auditLogId, $this->expandedEntries, true);
    }

    public function payloadJson(AuditLog $auditLog): string
    {
        if ($auditLog->payload === null) {
            return '';
        }

        $encodedPayload = json_encode($auditLog->payload, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES);

        if (! is_string($encodedPayload)) {
            Log::warning('Audit log payload could not be encoded for display.', [
                'audit_log_id' => $auditLog->id,
                'action' => $auditLog->action,
            ]);

            return 'Payload encoding failed.';
        }

        return $encodedPayload;
    }
}