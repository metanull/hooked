BeforeAll {
    # Load dependency first (PSGitOps provides Reset-GitRepository, Sync-GitRepository, etc.)
    $DependencyPath = Join-Path $PSScriptRoot '..\..\src\MetaNull.PSGitOps\MetaNull.PSGitOps.psd1'
    Import-Module $DependencyPath -Force
    $ModulePath = Join-Path $PSScriptRoot '..\..\src\MetaNull.PSWebAppBuilder\MetaNull.PSWebAppBuilder.psd1'
    Import-Module $ModulePath -Force
}

# All tests use Pester mocks — no real git, composer, npm, or SMTP operations.
# This ensures tests are isolated, environment-agnostic, and CI-safe.

Describe 'Invoke-WebAppUpdate' {
    BeforeAll {
        # Mock git operations from PSGitOps
        Mock Reset-GitRepository { } -ModuleName 'MetaNull.PSWebAppBuilder'
        Mock Sync-GitRepository { } -ModuleName 'MetaNull.PSWebAppBuilder'
        Mock Set-GitCurrentBranch { } -ModuleName 'MetaNull.PSWebAppBuilder'
        Mock git {
            $joined = $Args -join ' '
            $global:LASTEXITCODE = 0
            switch -Wildcard ($joined) {
                'status*' { 'Your branch is behind' }
                'clean*' { 'Removing untracked files' }
                'fetch*' { '' }
                'reset*' { 'HEAD is now at abc1234' }
                'log*' { 'abc1234 - (1 hour ago) Test commit - Author' }
                default { '' }
            }
        } -ModuleName 'MetaNull.PSWebAppBuilder'
        Mock Send-MailMessage { } -ModuleName 'MetaNull.PSWebAppBuilder'

        $TestDir = (New-Item -ItemType Directory -Path "TestDrive:\test-app" -Force).FullName
    }

    Context 'When update is needed' {
        It 'Executes the pull and build pipeline' {
            $executed = @{}
            $sb = [ordered]@{
                TestStep = { $global:WebAppTestStepExecuted = $true }
            }
            Invoke-WebAppUpdate -Directory $TestDir -Branch 'main' -Alias 'TestApp' -Url 'https://test.example.com' -ScriptBlock $sb -Force
            $global:WebAppTestStepExecuted | Should -BeTrue
            Remove-Variable WebAppTestStepExecuted -Scope Global -ErrorAction SilentlyContinue
        }

        It 'Calls git fetch and reset when Force is set' {
            $sb = [ordered]@{
                NoOp = { }
            }
            Invoke-WebAppUpdate -Directory $TestDir -Branch 'main' -Alias 'TestApp' -Url 'https://test.example.com' -ScriptBlock $sb -Force
            Should -Invoke git -ModuleName 'MetaNull.PSWebAppBuilder' -ParameterFilter {
                ($Args -join ' ') -match 'fetch'
            }
        }

        It 'Executes all script block steps in order' {
            $global:WebAppStepOrder = @()
            $sb = [ordered]@{
                First  = { $global:WebAppStepOrder += 'first' }
                Second = { $global:WebAppStepOrder += 'second' }
                Third  = { $global:WebAppStepOrder += 'third' }
            }
            Invoke-WebAppUpdate -Directory $TestDir -Branch 'main' -Alias 'TestApp' -Url 'https://test.example.com' -ScriptBlock $sb -Force
            $global:WebAppStepOrder | Should -Be @('first', 'second', 'third')
            Remove-Variable WebAppStepOrder -Scope Global -ErrorAction SilentlyContinue
        }
    }

    Context 'When code is up-to-date and Force is not set' {
        BeforeAll {
            Mock git {
                $joined = $Args -join ' '
                $global:LASTEXITCODE = 0
                switch -Wildcard ($joined) {
                    'status*' { "Your branch is up to date with 'origin/main'." }
                    default { '' }
                }
            } -ModuleName 'MetaNull.PSWebAppBuilder'
        }
        It 'Still executes the build pipeline' {
            $global:WebAppBuildRan = $false
            $sb = [ordered]@{
                BuildStep = { $global:WebAppBuildRan = $true }
            }
            Invoke-WebAppUpdate -Directory $TestDir -Branch 'main' -Alias 'TestApp' -Url 'https://test.example.com' -ScriptBlock $sb
            $global:WebAppBuildRan | Should -BeTrue
            Remove-Variable WebAppBuildRan -Scope Global -ErrorAction SilentlyContinue
        }
    }

    Context 'When an error occurs' {
        It 'Throws and propagates the error' {
            $sb = [ordered]@{
                FailStep = { throw 'Build failed!' }
            }
            { Invoke-WebAppUpdate -Directory $TestDir -Branch 'main' -Alias 'TestApp' -Url 'https://test.example.com' -ScriptBlock $sb -Force } | Should -Throw '*Build failed*'
        }
    }

    Context 'With email notifications' {
        It 'Sends start and completion emails when SMTP is configured' {
            $sb = [ordered]@{ NoOp = { } }
            Invoke-WebAppUpdate -Directory $TestDir -Branch 'main' -Alias 'TestApp' -Url 'https://test.example.com' -ScriptBlock $sb -Force -SmtpServer 'smtp.test.com' -SmtpFrom 'ci@test.com' -To 'dev@test.com'
            # At least 2 calls: start + completion
            Should -Invoke Send-MailMessage -ModuleName 'MetaNull.PSWebAppBuilder' -Times 2 -Exactly
        }
    }
}

Describe 'Build-LaravelApi' {
    BeforeAll {
        Mock Invoke-WebAppUpdate { } -ModuleName 'MetaNull.PSWebAppBuilder'
    }

    It 'Calls Invoke-WebAppUpdate with Building and Optimizing steps' {
        Build-LaravelApi -Directory 'C:\app' -Branch 'master' -Alias 'LaravelApp' -Url 'https://laravel.example.com'
        Should -Invoke Invoke-WebAppUpdate -ModuleName 'MetaNull.PSWebAppBuilder' -Times 1 -Exactly -ParameterFilter {
            $ScriptBlock.Count -eq 2 -and
            $ScriptBlock.Contains('Building') -and
            $ScriptBlock.Contains('Optimizing')
        }
    }

    It 'Passes all parameters through to Invoke-WebAppUpdate' {
        Build-LaravelApi -Directory 'C:\app' -Branch 'master' -Alias 'LaravelApp' -Url 'https://laravel.example.com' -MutexName 'TestMutex' -Force
        Should -Invoke Invoke-WebAppUpdate -ModuleName 'MetaNull.PSWebAppBuilder' -Times 1 -Exactly -ParameterFilter {
            $Directory -eq 'C:\app' -and
            $Branch -eq 'master' -and
            $Alias -eq 'LaravelApp' -and
            $MutexName -eq 'TestMutex' -and
            $Force -eq $true
        }
    }
}

Describe 'Build-LumenApi' {
    BeforeAll {
        Mock Invoke-WebAppUpdate { } -ModuleName 'MetaNull.PSWebAppBuilder'
    }

    It 'Calls Invoke-WebAppUpdate with Building and Optimizing steps' {
        Build-LumenApi -Directory 'C:\api' -Branch 'master' -Alias 'LumenApi' -Url 'https://lumen.example.com'
        Should -Invoke Invoke-WebAppUpdate -ModuleName 'MetaNull.PSWebAppBuilder' -Times 1 -Exactly -ParameterFilter {
            $ScriptBlock.Count -eq 2 -and
            $ScriptBlock.Contains('Building') -and
            $ScriptBlock.Contains('Optimizing')
        }
    }
}

Describe 'Build-NodeJSClient' {
    BeforeAll {
        Mock Invoke-WebAppUpdate { } -ModuleName 'MetaNull.PSWebAppBuilder'
    }

    It 'Calls Invoke-WebAppUpdate with all 5 Node.js build steps' {
        Build-NodeJSClient -Directory 'C:\client' -Branch 'master' -Alias 'VueClient' -Url 'https://vue.example.com'
        Should -Invoke Invoke-WebAppUpdate -ModuleName 'MetaNull.PSWebAppBuilder' -Times 1 -Exactly -ParameterFilter {
            $ScriptBlock.Count -eq 5 -and
            $ScriptBlock.Contains('CleaningUp') -and
            $ScriptBlock.Contains('Installing') -and
            $ScriptBlock.Contains('Updating') -and
            $ScriptBlock.Contains('Building') -and
            $ScriptBlock.Contains('Deploying')
        }
    }
}

Describe 'Update-GitLatest' {
    BeforeAll {
        Mock Invoke-WebAppUpdate { } -ModuleName 'MetaNull.PSWebAppBuilder'
    }

    It 'Calls Invoke-WebAppUpdate with a single NothingToDo step' {
        Update-GitLatest -Directory 'C:\repo' -Branch 'main' -Alias 'RepoOnly' -Url 'https://repo.example.com'
        Should -Invoke Invoke-WebAppUpdate -ModuleName 'MetaNull.PSWebAppBuilder' -Times 1 -Exactly -ParameterFilter {
            $ScriptBlock.Count -eq 1 -and
            $ScriptBlock.Contains('NothingToDo')
        }
    }

    It 'Passes Force flag through' {
        Update-GitLatest -Directory 'C:\repo' -Branch 'main' -Alias 'RepoOnly' -Url 'https://repo.example.com' -Force
        Should -Invoke Invoke-WebAppUpdate -ModuleName 'MetaNull.PSWebAppBuilder' -Times 1 -Exactly -ParameterFilter {
            $Force -eq $true
        }
    }
}
