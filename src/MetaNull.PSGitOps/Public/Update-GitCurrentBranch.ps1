Function Update-GitCurrentBranch {
    <#
        .Synopsis
            Pull all the latest changes from the remote repository branch (git pull).
        .Example
            Update-GitCurrentBranch
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Delegates to git pull; ShouldProcess not appropriate for CLI wrapper')]
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
        $Output = (git pull *>&1)
        if ($LASTEXITCODE -ne 0) {
            throw $Output
        }
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] $([string[]]$Output)"
    }
}
