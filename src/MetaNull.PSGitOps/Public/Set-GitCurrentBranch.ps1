Function Set-GitCurrentBranch {
    <#
        .Synopsis
            Switch the active branch of the local repository (git checkout).
        .Parameter Branch
            Name of the branch to switch to.
        .Example
            Set-GitCurrentBranch -Branch 'master'
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Delegates to git checkout; ShouldProcess not appropriate for CLI wrapper')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, HelpMessage = 'Name of the branch to switch to.')]
        [Alias('Name')]
        [String]$Branch
    )
    Begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"
    }
    End {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
    Process {
        $Output = (git checkout $Branch *>&1)
        if ($LASTEXITCODE -ne 0) {
            throw $Output
        }
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] $([string[]]$Output)"
    }
}
