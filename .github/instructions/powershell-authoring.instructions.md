---
description: "Use when: writing PowerShell functions, creating modules, adding cmdlets, designing parameters, implementing error handling in .ps1 or .psm1 files. Enforces module structure, PS5.1/PS7 compatibility, and consistent patterns."
applyTo: ["**/*.ps1", "**/*.psm1", "**/*.psd1"]
---
# PowerShell Module Authoring Conventions

## PowerShell version compatibility

All code MUST work on **PowerShell 5.1** (Windows built-in) and **PowerShell 7.x** (pwsh).

**Forbidden PS7-only syntax:**
- `??` (null-coalescing) — use `if ($null -eq $x) { ... }` instead
- `??=` (null-coalescing assignment)
- `?.` (null-conditional member access)
- `ForEach-Object -Parallel`
- Ternary `$x ? $a : $b` — use `if ($x) { $a } else { $b }`
- Pipeline chain operators `&&` and `||`
- `Clean {}` block in functions

**Safe patterns for both versions:**
- `[System.Collections.Specialized.OrderedDictionary]` (not `[ordered]` as a parameter type)
- `$null -eq $x` (put `$null` on the left for array safety)
- Standard `try/catch/finally`
- `*>&1` redirection for capturing all streams

## Module folder structure

```
ModuleName/
├── ModuleName.psd1      # Manifest — explicit FunctionsToExport
├── ModuleName.psm1      # Bootstrap — dot-sources Public/ and Private/
├── Public/              # One .ps1 per exported function
└── Private/             # One .ps1 per internal helper (not exported)
```

## Module bootstrap (.psm1)

```powershell
$Public = @(Get-ChildItem -Path "$PSScriptRoot\Public\*.ps1" -ErrorAction SilentlyContinue)
$Private = @(Get-ChildItem -Path "$PSScriptRoot\Private\*.ps1" -ErrorAction SilentlyContinue)

foreach ($import in @($Public + $Private)) {
    try {
        . $import.FullName
    } catch {
        Write-Error "Failed to import function $($import.FullName): $_"
    }
}

Export-ModuleMember -Function $Public.BaseName
```

## Function template

Every public function must follow this structure:

```powershell
function Verb-Noun {
    [CmdletBinding()]
    [OutputType([ReturnType])]
    param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [string]$InputString
    )
    Begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"
        Write-Progress -Id 1 -PercentComplete -1 -Activity $MyInvocation.MyCommand.Name
    }
    Process {
        # Implementation
    }
    End {
        Write-Progress -Id 1 -Completed -Activity $MyInvocation.MyCommand.Name
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}
```

### Required elements

| Element | Rule |
|---|---|
| `[CmdletBinding()]` | Always present |
| `[OutputType([...])]` | Always declared, matching actual output |
| `Begin/Process/End` | Use when pipeline input is accepted; otherwise a plain body is fine |
| Verbose logging | `Write-Verbose "[$($MyInvocation.MyCommand.Name)] message"` |
| Progress | `Write-Progress` in Begin/End for longer operations |

### Parameter conventions

- **Type declarations** on all parameters (primary validation gate)
- `[Parameter(Mandatory = $true)]` — never leave mandatory implicit
- `ValueFromPipeline = $true` where pipeline input makes sense
- `ParameterSetName` for mutually exclusive parameter groups
- `[Alias()]` for common short names
- `[AllowEmptyString()]` when empty is a valid input

### Naming

| Element | Convention | Example |
|---|---|---|
| Functions | Verb-Noun (approved verbs) | `Get-GitRepository`, `ConvertTo-DotEnv` |
| Parameters | PascalCase | `$InputString`, `$Repository` |
| Internal variables | PascalCase | `$Output`, `$OutputObject` |
| Regex constants | SCREAMING_SNAKE | `$REGEX`, `$EMPTY` |

## Error handling

### External commands (git, etc.)

```powershell
$Output = (git fetch *>&1)
if ($LASTEXITCODE -ne 0) {
    throw $Output
}
```

### Terminating vs non-terminating

- **`throw`** for errors the caller must handle (invalid input, command failure)
- **`Write-Error`** for non-fatal problems (module import issues, skippable items)
- **`Write-Warning`** for recoverable data issues (duplicate keys, fallback behavior)
- **Never silently swallow errors** — every catch block must log or re-throw

## Manifest (.psd1)

- `PowerShellVersion = '5.1'`
- `FunctionsToExport` must list every public function explicitly (no wildcards)
- `CmdletsToExport = @()`, `VariablesToExport = @()`, `AliasesToExport = @()` — empty arrays, not `'*'`
