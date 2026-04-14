# Hooked

Custom CI/CD orchestration tool for Windows Server.

Laravel 12 + Livewire application that manages deployments via Windows Task Scheduler and PowerShell modules.

## Architecture

```
HTTP request (Bitbucket webhook / Admin browser)
  → Laravel 12 (Livewire UI + webhook controllers)
    → PowerShell modules (via symfony/process)
      → Windows Task Scheduler (async execution)
      → Windows Registry (runtime configuration)
```

## Components

| Component | Purpose |
|-----------|---------|
| Laravel app | Web UI, webhook ingestion, auth, audit logging |
| MetaNull.PSStringToolkit | String/encoding/conversion utilities (PSGallery) |
| MetaNull.PSGitOps | Git operations (PSGallery) |
| MetaNull.PSCredentialCache | DPAPI credential caching (PSGallery) |
| MetaNull.PSDeployQueue | Registry-backed queue + Task Scheduler integration (PSGallery) |
| MetaNull.PSWebAppBuilder | Build pipelines for Laravel/Node apps (PSGallery) |

## Requirements

- PHP 8.2+
- Laravel 12
- PowerShell 5.1+ (Windows)
- Windows Task Scheduler
- SQLite

## License

MIT
