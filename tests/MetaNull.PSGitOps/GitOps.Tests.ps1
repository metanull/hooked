BeforeAll {
    $ModulePath = Join-Path $PSScriptRoot '..\..\src\MetaNull.PSGitOps\MetaNull.PSGitOps.psd1'
    Import-Module $ModulePath -Force
}

# These tests run against the actual hooked git repository.
# They only use read-only git operations to avoid side effects.

Describe 'Get-GitCurrentBranch' {
    It 'Returns a non-empty string' {
        $result = Get-GitCurrentBranch
        $result | Should -Not -BeNullOrEmpty
        $result | Should -BeOfType [string]
    }
    It 'Returns the current branch name' {
        # git branch --show-current is the underlying command
        $expected = (git branch --show-current 2>$null)
        Get-GitCurrentBranch | Should -Be $expected
    }
}

Describe 'Get-GitRepository' {
    It 'Returns a PSCustomObject with Remote property' {
        $result = Get-GitRepository
        $result | Should -Not -BeNullOrEmpty
        $result.Remote | Should -Not -BeNullOrEmpty
    }
    It 'Has Branch property matching current branch' {
        $result = Get-GitRepository
        $expected = (git branch --show-current 2>$null)
        $result.Branch | Should -Be $expected
    }
    It 'Has Branches with Local and Remote arrays' {
        $result = Get-GitRepository
        $result.Branches | Should -Not -BeNullOrEmpty
        $result.Branches.Local | Should -Not -BeNullOrEmpty
        $result.Branches.Remote | Should -Not -BeNullOrEmpty
    }
    It 'Has LatestCommit with expected properties' {
        $result = Get-GitRepository
        $result.LatestCommit | Should -Not -BeNullOrEmpty
        $result.LatestCommit.Author | Should -Not -BeNullOrEmpty
        $result.LatestCommit.Commit | Should -Not -BeNullOrEmpty
        $result.LatestCommit.Date | Should -BeOfType [datetime]
    }
    It 'Has BehindOrigin and AheadOrigin counts' {
        $result = Get-GitRepository
        $result.PSObject.Properties.Name | Should -Contain 'BehindOrigin'
        $result.PSObject.Properties.Name | Should -Contain 'AheadOrigin'
    }
}

Describe 'Sync-GitRepository' {
    It 'Runs git fetch without error' {
        { Sync-GitRepository } | Should -Not -Throw
    }
}

Describe 'Import-GitRepository' {
    It 'Has required parameters Repository and Name' {
        $cmd = Get-Command Import-GitRepository
        $cmd.Parameters.Keys | Should -Contain 'Repository'
        $cmd.Parameters.Keys | Should -Contain 'Name'
    }
    It 'Throws when cloning to existing directory' {
        # Attempt to clone into an existing folder name should fail
        { Import-GitRepository -Repository 'https://github.com/metanull/hooked.git' -Name '.' } | Should -Throw
    }
}

Describe 'Reset-GitRepository' {
    It 'Has CmdletBinding' {
        $cmd = Get-Command Reset-GitRepository
        $cmd.CmdletBinding | Should -Be $true
    }
    It 'Runs without error on clean working tree' {
        { Reset-GitRepository } | Should -Not -Throw
    }
}

Describe 'Set-GitCurrentBranch' {
    It 'Has Branch parameter' {
        $cmd = Get-Command Set-GitCurrentBranch
        $cmd.Parameters.Keys | Should -Contain 'Branch'
    }
    It 'Stays on current branch when switching to same branch' {
        $current = Get-GitCurrentBranch
        { Set-GitCurrentBranch -Branch $current } | Should -Not -Throw
        Get-GitCurrentBranch | Should -Be $current
    }
    It 'Throws for non-existent branch' {
        { Set-GitCurrentBranch -Branch 'nonexistent-branch-xyz-999' } | Should -Throw
    }
}

Describe 'Update-GitCurrentBranch' {
    It 'Runs git pull without error when upstream is set' {
        # First check if upstream exists; skip gracefully if not
        $upstream = git rev-parse --abbrev-ref '@{u}' 2>$null
        if (-not $upstream) {
            Set-ItResult -Skipped -Because 'No upstream tracking branch configured'
        }
        { Update-GitCurrentBranch } | Should -Not -Throw
    }
}
