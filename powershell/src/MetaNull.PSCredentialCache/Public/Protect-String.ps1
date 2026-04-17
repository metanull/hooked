function Protect-String {
    <#
        .SYNOPSIS
            Encrypt a string using DPAPI (user-scoped).
        .DESCRIPTION
            Converts a plain text string to a DPAPI-encrypted string using the current user's credentials.
            The encrypted string can only be decrypted by the same user on the same machine.
        .PARAMETER InputString
            The plain text string to encrypt.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
        [string]$InputString
    )
    Begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"
        [string]$OutputString = ""
    }
    Process {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"
        $OutputString = ($InputString | ConvertTo-SecureString -AsPlainText -Force | ConvertFrom-SecureString)
    }
    End {
        $OutputString | Write-Output
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}
