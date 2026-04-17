---
description: "Use when: writing Pester tests, creating *.Tests.ps1 files, adding test coverage, designing test fixtures, mocking PowerShell commands. Enforces isolation, environment-agnosticism, and mandatory faking."
applyTo: "**/*.Tests.ps1"
---
# PowerShell Pester Tests — Authoring Rules

## PowerShell version compatibility

Tests MUST run on both **PowerShell 5.1** and **PowerShell 7.x**. Do not use PS7-only syntax (`??`, `?.`, ternary `? :`, `&&`/`||` pipeline chains, `ForEach-Object -Parallel`, `Clean {}`).

## Isolation is mandatory

Tests MUST NOT depend on or interact with:
- The current git repository (no real `git` CLI calls)
- The host file system outside of `TestDrive:\`
- Windows Registry, Credential Manager, or Task Scheduler
- Network resources or remote sessions
- System clock (use deterministic dates)

Even read-only operations against the real environment are **not reliable** — they break on CI runners, fresh clones, or different machines.

## Use Pester faking for all external dependencies

Every external command or side-effect-producing function must be faked with `Mock`:

```powershell
Describe 'Get-GitCurrentBranch' {
    BeforeAll {
        Mock git { 'feature/my-branch' } -ParameterFilter { ($Args -join ' ') -eq 'branch --show-current' }
    }
    It 'Returns the current branch name' {
        Get-GitCurrentBranch | Should -Be 'feature/my-branch'
    }
    It 'Calls git branch --show-current' {
        Should -Invoke git -Times 1 -Exactly
    }
}
```

### What to mock

| Dependency | Mock target |
|---|---|
| Git CLI | `Mock git { ... }` with `-ParameterFilter` matching `$Args` |
| File I/O | Use `TestDrive:\` or mock `Get-Content`/`Set-Content` |
| Registry | Mock `Get-ItemProperty`, `Set-ItemProperty`, etc. |
| Remote sessions | Mock `New-PSSession`, `Invoke-Command` |
| Credentials | Mock `Get-Credential` or module-internal accessors |
| Current date/time | Mock `Get-Date` to return a fixed `[datetime]` |

### Use `InModuleScope` when mocking internal functions

```powershell
InModuleScope 'MetaNull.PSGitOps' {
    Describe 'Get-GitRepository' {
        BeforeAll {
            Mock git { 'abc1234 Author Name 2025-01-15' } -ParameterFilter {
                ($Args -join ' ') -like 'log*'
            }
        }
        It 'Parses the latest commit' {
            $result = Get-GitRepository
            $result.LatestCommit.Commit | Should -Be 'abc1234'
        }
    }
}
```

## Use `TestDrive:\` for file system operations

```powershell
BeforeAll {
    Set-Content -Path "TestDrive:\test.env" -Value "KEY=value`nOTHER=data"
}
It 'Parses the .env file' {
    $result = ConvertFrom-DotEnv -Path "TestDrive:\test.env"
    $result.KEY | Should -Be 'value'
}
```

## Pure functions: inline test data, no mocking needed

Functions with no side effects (string encoding, hashing, serialization) need no mocks — pass explicit input and assert output:

```powershell
It 'Encodes spaces as plus signs' {
    ConvertTo-UrlEncoded -InputString 'hello world' | Should -Be 'hello+world'
}
```

## Test structure

- **One `Describe` block per function** being tested
- **`BeforeAll`**: import module with `-Force`, set up shared mocks
- **`BeforeEach`**: reset per-test state if mocks vary between `It` blocks
- **`AfterAll`**: not usually needed (Pester cleans up mocks automatically)
- **Verify calls**: use `Should -Invoke` to confirm mocked commands were called with expected arguments
