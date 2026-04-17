BeforeAll {
    $ModulePath = Join-Path $PSScriptRoot '..\..\src\MetaNull.PSGitOps\MetaNull.PSGitOps.psd1'
    Import-Module $ModulePath -Force
}

# All tests use Pester mocks — no real git commands are executed.
# This ensures tests are isolated, environment-agnostic, and CI-safe.

Describe 'Get-GitCurrentBranch' {
    Context 'When git succeeds' {
        BeforeAll {
            Mock git {
                $global:LASTEXITCODE = 0
                'feature/mock-branch'
            } -ModuleName 'MetaNull.PSGitOps'
        }
        It 'Returns a non-empty string' {
            $result = Get-GitCurrentBranch
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [string]
        }
        It 'Returns the branch name from git output' {
            Get-GitCurrentBranch | Should -Be 'feature/mock-branch'
        }
        It 'Invokes git branch --show-current' {
            Get-GitCurrentBranch | Out-Null
            Should -Invoke git -ModuleName 'MetaNull.PSGitOps' -Times 1 -Exactly -ParameterFilter {
                ($Args -join ' ') -eq 'branch --show-current'
            }
        }
    }
    Context 'When git fails' {
        BeforeAll {
            Mock git {
                $global:LASTEXITCODE = 128
                'fatal: not a git repository'
            } -ModuleName 'MetaNull.PSGitOps'
        }
        It 'Throws on non-zero exit code' {
            { Get-GitCurrentBranch } | Should -Throw
        }
    }
}

Describe 'Get-GitRepository' {
    Context 'When repository has commits but no tags' {
        BeforeAll {
            Mock git {
                $joined = $Args -join ' '
                $global:LASTEXITCODE = 0
                switch -Wildcard ($joined) {
                    'remote get-url origin' {
                        'https://github.com/test/repo.git'
                        break
                    }
                    'branch --show-current' {
                        'main'
                        break
                    }
                    'branch -a --no-color' {
                        '* main'
                        '  develop'
                        '  remotes/origin/main'
                        '  remotes/origin/develop'
                        break
                    }
                    'rev-list origin*' {
                        "0`t2"
                        break
                    }
                    'rev-parse main' {
                        'abc1234567890abcdef1234567890abcdef123456'
                        break
                    }
                    'rev-list --tags*' {
                        # No tags — return nothing
                        break
                    }
                    default {
                        # git show for the commit
                        "2025-01-15 10:00:00 +0000`tJohn Doe`tjohn@example.com`tInitial commit`tabc1234`tabc1234567890abcdef1234567890abcdef123456"
                        break
                    }
                }
            } -ModuleName 'MetaNull.PSGitOps'
        }
        It 'Returns a PSCustomObject with Remote' {
            $result = Get-GitRepository
            $result | Should -Not -BeNullOrEmpty
            $result.Remote | Should -Be 'https://github.com/test/repo.git'
        }
        It 'Has Branch from git branch --show-current' {
            $result = Get-GitRepository
            $result.Branch | Should -Be 'main'
        }
        It 'Has Branches with Local and Remote arrays' {
            $result = Get-GitRepository
            $result.Branches.Local | Should -Contain 'main'
            $result.Branches.Local | Should -Contain 'develop'
            $result.Branches.Remote | Should -Contain 'remotes/origin/main'
            $result.Branches.Remote | Should -Contain 'remotes/origin/develop'
        }
        It 'Has BehindOrigin and AheadOrigin from rev-list' {
            $result = Get-GitRepository
            $result.BehindOrigin | Should -Be '0'
            $result.AheadOrigin | Should -Be '2'
        }
        It 'Has LatestCommit with parsed properties' {
            $result = Get-GitRepository
            $result.LatestCommit | Should -Not -BeNullOrEmpty
            $result.LatestCommit.Author | Should -Be 'John Doe'
            $result.LatestCommit.Email | Should -Be 'john@example.com'
            $result.LatestCommit.Description | Should -Be 'Initial commit'
            $result.LatestCommit.ShortCommit | Should -Be 'abc1234'
            $result.LatestCommit.Commit | Should -Be 'abc1234567890abcdef1234567890abcdef123456'
            $result.LatestCommit.Date | Should -BeOfType [datetime]
        }
    }

    Context 'When repository has a tag' {
        BeforeAll {
            Mock git {
                $joined = $Args -join ' '
                $global:LASTEXITCODE = 0
                switch -Wildcard ($joined) {
                    'remote get-url origin' {
                        'https://github.com/test/repo.git'
                        break
                    }
                    'branch --show-current' {
                        'main'
                        break
                    }
                    'branch -a --no-color' {
                        '* main'
                        '  remotes/origin/main'
                        break
                    }
                    'rev-list origin*' {
                        "0`t0"
                        break
                    }
                    'rev-parse main' {
                        'abc1234567890abcdef1234567890abcdef123456'
                        break
                    }
                    'rev-list --tags*' {
                        'def4567890abcdef1234567890abcdef1234567890'
                        break
                    }
                    'describe *' {
                        'v1.0.0'
                        break
                    }
                    default {
                        # git show — differentiate commit vs tag by revision argument
                        if ($joined -like '* abc1234567890abcdef1234567890abcdef123456') {
                            "2025-01-15 10:00:00 +0000`tJohn Doe`tjohn@example.com`tInitial commit`tabc1234`tabc1234567890abcdef1234567890abcdef123456"
                        } elseif ($joined -like '* def4567890abcdef1234567890abcdef1234567890') {
                            "2025-02-01 12:00:00 +0000`tJane Smith`tjane@example.com`tRelease v1`tdef4567`tdef4567890abcdef1234567890abcdef1234567890"
                        }
                        break
                    }
                }
            } -ModuleName 'MetaNull.PSGitOps'
        }
        It 'Has LatestTag with parsed properties' {
            $result = Get-GitRepository
            $result.LatestTag | Should -Not -BeNullOrEmpty
            $result.LatestTag.Tag | Should -Be 'v1.0.0'
            $result.LatestTag.Author | Should -Be 'Jane Smith'
            $result.LatestTag.Email | Should -Be 'jane@example.com'
            $result.LatestTag.Date | Should -BeOfType [datetime]
        }
    }

    Context 'When git fails' {
        BeforeAll {
            Mock git {
                $global:LASTEXITCODE = 128
                'fatal: not a git repository'
            } -ModuleName 'MetaNull.PSGitOps'
        }
        It 'Throws on non-zero exit code' {
            { Get-GitRepository } | Should -Throw
        }
    }
}

Describe 'Sync-GitRepository' {
    Context 'When fetch succeeds' {
        BeforeAll {
            Mock git {
                $global:LASTEXITCODE = 0
            } -ModuleName 'MetaNull.PSGitOps'
        }
        It 'Does not throw' {
            { Sync-GitRepository } | Should -Not -Throw
        }
        It 'Invokes git fetch' {
            Sync-GitRepository
            Should -Invoke git -ModuleName 'MetaNull.PSGitOps' -Times 1 -Exactly -ParameterFilter {
                ($Args -join ' ') -eq 'fetch'
            }
        }
    }
    Context 'When fetch fails' {
        BeforeAll {
            Mock git {
                $global:LASTEXITCODE = 1
                'fatal: Could not read from remote repository.'
            } -ModuleName 'MetaNull.PSGitOps'
        }
        It 'Throws on non-zero exit code' {
            { Sync-GitRepository } | Should -Throw
        }
    }
}

Describe 'Import-GitRepository' {
    It 'Has required parameters Repository and Name' {
        $cmd = Get-Command Import-GitRepository
        $cmd.Parameters.Keys | Should -Contain 'Repository'
        $cmd.Parameters.Keys | Should -Contain 'Name'
    }
    Context 'When clone succeeds' {
        BeforeAll {
            Mock git {
                $global:LASTEXITCODE = 0
                "Cloning into 'test-repo'..."
            } -ModuleName 'MetaNull.PSGitOps'
        }
        It 'Does not throw' {
            { Import-GitRepository -Repository 'https://github.com/test/repo.git' -Name 'test-repo' } | Should -Not -Throw
        }
        It 'Invokes git clone with correct arguments' {
            Import-GitRepository -Repository 'https://github.com/test/repo.git' -Name 'test-repo'
            Should -Invoke git -ModuleName 'MetaNull.PSGitOps' -Times 1 -Exactly -ParameterFilter {
                $Args[0] -eq 'clone' -and $Args[2] -eq 'test-repo'
            }
        }
    }
    Context 'When clone fails' {
        BeforeAll {
            Mock git {
                $global:LASTEXITCODE = 128
                "fatal: destination path 'existing' already exists and is not an empty directory."
            } -ModuleName 'MetaNull.PSGitOps'
        }
        It 'Throws on non-zero exit code' {
            { Import-GitRepository -Repository 'https://github.com/test/repo.git' -Name 'existing' } | Should -Throw
        }
    }
}

Describe 'Reset-GitRepository' {
    It 'Has CmdletBinding' {
        $cmd = Get-Command Reset-GitRepository
        $cmd.CmdletBinding | Should -Be $true
    }
    Context 'When reset succeeds' {
        BeforeAll {
            Mock git {
                $global:LASTEXITCODE = 0
                'HEAD is now at abc1234 Initial commit'
            } -ModuleName 'MetaNull.PSGitOps'
        }
        It 'Does not throw' {
            { Reset-GitRepository } | Should -Not -Throw
        }
        It 'Invokes git reset --hard HEAD' {
            Reset-GitRepository
            Should -Invoke git -ModuleName 'MetaNull.PSGitOps' -Times 1 -Exactly -ParameterFilter {
                ($Args -join ' ') -eq 'reset --hard HEAD'
            }
        }
    }
    Context 'When reset fails' {
        BeforeAll {
            Mock git {
                $global:LASTEXITCODE = 1
                'fatal: Failed to resolve HEAD'
            } -ModuleName 'MetaNull.PSGitOps'
        }
        It 'Throws on non-zero exit code' {
            { Reset-GitRepository } | Should -Throw
        }
    }
}

Describe 'Set-GitCurrentBranch' {
    It 'Has Branch parameter' {
        $cmd = Get-Command Set-GitCurrentBranch
        $cmd.Parameters.Keys | Should -Contain 'Branch'
    }
    Context 'When checkout succeeds' {
        BeforeAll {
            Mock git {
                $global:LASTEXITCODE = 0
                "Switched to branch 'develop'"
            } -ModuleName 'MetaNull.PSGitOps'
        }
        It 'Does not throw' {
            { Set-GitCurrentBranch -Branch 'develop' } | Should -Not -Throw
        }
        It 'Invokes git checkout with the branch name' {
            Set-GitCurrentBranch -Branch 'develop'
            Should -Invoke git -ModuleName 'MetaNull.PSGitOps' -Times 1 -Exactly -ParameterFilter {
                $Args[0] -eq 'checkout' -and $Args[1] -eq 'develop'
            }
        }
    }
    Context 'When branch does not exist' {
        BeforeAll {
            Mock git {
                $global:LASTEXITCODE = 1
                "error: pathspec 'nonexistent' did not match any file(s) known to git"
            } -ModuleName 'MetaNull.PSGitOps'
        }
        It 'Throws on non-zero exit code' {
            { Set-GitCurrentBranch -Branch 'nonexistent' } | Should -Throw
        }
    }
}

Describe 'Update-GitCurrentBranch' {
    Context 'When pull succeeds' {
        BeforeAll {
            Mock git {
                $global:LASTEXITCODE = 0
                'Already up to date.'
            } -ModuleName 'MetaNull.PSGitOps'
        }
        It 'Does not throw' {
            { Update-GitCurrentBranch } | Should -Not -Throw
        }
        It 'Invokes git pull' {
            Update-GitCurrentBranch
            Should -Invoke git -ModuleName 'MetaNull.PSGitOps' -Times 1 -Exactly -ParameterFilter {
                ($Args -join ' ') -eq 'pull'
            }
        }
    }
    Context 'When pull fails' {
        BeforeAll {
            Mock git {
                $global:LASTEXITCODE = 128
                'fatal: not a git repository'
            } -ModuleName 'MetaNull.PSGitOps'
        }
        It 'Throws on non-zero exit code' {
            { Update-GitCurrentBranch } | Should -Throw
        }
    }
}
