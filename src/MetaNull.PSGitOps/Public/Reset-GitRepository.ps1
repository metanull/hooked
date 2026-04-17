Function Reset-GitRepository {
    <#
        .Synopsis
            Reset the local repository to match the remote (discards all local changes).
        .Description
            Runs git reset --hard HEAD to discard all uncommitted local changes.
        .Example
            Reset-GitRepository
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Delegates to git reset; ShouldProcess not appropriate for CLI wrapper')]
    [CmdletBinding()]
    param()
    Begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"
        Write-Progress -Id 1 -PercentComplete -1 -Activity $MyInvocation.MyCommand.Name
    }
    End {
        Write-Progress -Id 1 -Completed -Activity $MyInvocation.MyCommand.Name
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
    Process {
        $Output = (git reset --hard HEAD *>&1)
        if ($LASTEXITCODE -ne 0) {
            throw $Output
        }
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] $([string[]]$Output)"
    }
}
