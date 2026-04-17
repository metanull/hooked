Function Sync-GitRepository {
    <#
        .Synopsis
            Fetch data from the remote repository (git fetch).
        .Example
            Sync-GitRepository
    #>
    [CmdletBinding()]
    [OutputType([bool])]
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
        $Output = (git fetch *>&1)
        if ($LASTEXITCODE -ne 0) {
            throw $Output
        }
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] $([string[]]$Output)"
    }
}
