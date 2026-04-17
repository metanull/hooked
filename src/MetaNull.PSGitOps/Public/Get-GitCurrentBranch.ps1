Function Get-GitCurrentBranch {
    <#
        .Synopsis
            Get the name of the current local branch.
        .Example
            Get-GitCurrentBranch   # => 'main'
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param()
    Begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"
        $OutputString = $null
    }
    End {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function ended"
        return $OutputString
    }
    Process {
        $Output = (git branch --show-current *>&1)
        if ($LASTEXITCODE -ne 0) {
            throw $Output
        }
        $OutputString = [string]$Output
    }
}
