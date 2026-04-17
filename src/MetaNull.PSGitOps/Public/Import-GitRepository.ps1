Function Import-GitRepository {
    <#
        .Synopsis
            Clone a remote GIT repository into the current directory.
        .Parameter Repository
            URI of the repository.
        .Parameter Name
            Leaf name of the directory for the cloned repository.
        .Example
            Import-GitRepository -Repository 'https://github.com/user/repo.git' -Name 'repo'
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = 'URI of the GIT repository.')]
        [Uri]$Repository,

        [Parameter(Mandatory = $true, Position = 1, HelpMessage = 'Leaf name of the directory where to store the local repository.')]
        [Alias('Leaf')]
        [String]$Name
    )
    Begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"
        Write-Progress -Id 1 -PercentComplete -1 -Activity $MyInvocation.MyCommand.Name
    }
    End {
        Write-Progress -Id 1 -Completed -Activity $MyInvocation.MyCommand.Name
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
    Process {
        $Output = (git clone $Repository.AbsoluteUri $Name *>&1)
        if ($LASTEXITCODE -ne 0) {
            throw $Output
        }
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] $([string[]]$Output)"
    }
}
