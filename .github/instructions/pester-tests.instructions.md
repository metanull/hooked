---
description: "Use when: running PowerShell tests, executing Pester, validating module changes, running *.Tests.ps1 files. Prevents VS Code freezes caused by the runTests tool blocking the Extension Host."
applyTo: "**/*.Tests.ps1"
---
# PowerShell Pester Tests — Execution Rules

## NEVER use the `runTests` tool for PowerShell Pester tests

The `runTests` tool executes Pester through the PowerShell Extension Host, which is single-threaded.
This blocks VS Code's UI thread and causes "not responding" freezes.

## ALWAYS run Pester via the terminal

Use `run_in_terminal` with `Invoke-Pester` instead:

```powershell
# Run all tests
Invoke-Pester -Path .\tests -Output Detailed

# Run a specific test file
Invoke-Pester -Path .\tests\MetaNull.PSGitOps\GitOps.Tests.ps1 -Output Detailed

# Run tests matching a name filter
Invoke-Pester -Path .\tests -Output Detailed -Filter @{ FullName = '*Get-GitCurrentBranch*' }
```

## Configuration

- Use `-Output Detailed` for full diagnostics, or `-Output Minimal` for CI summaries
- Set working directory to the repository root before invoking Pester (module paths are relative)
- Use `mode=sync` with a generous timeout (e.g. 60000) for normal test runs
