function Unprotect-String {
    <#
        .SYNOPSIS
            Decrypt a DPAPI-encrypted string.
        .DESCRIPTION
            Converts a DPAPI-encrypted string (or SecureString) back to plain text.
            Only works for the same user on the same machine that performed the encryption.
        .PARAMETER InputString
            The DPAPI-encrypted string to decrypt.
        .PARAMETER InputSecureString
            A SecureString to decrypt.
    #>
    [CmdletBinding(DefaultParameterSetName = 'string')]
    [OutputType([string])]
    param(
        [Parameter(ParameterSetName = 'string', Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
        [string]$InputString,

        [Parameter(ParameterSetName = 'securestring', Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
        [System.Security.SecureString]$InputSecureString
    )
    Begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"
        [string]$OutputString = $null
    }
    Process {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"
        switch ($PsCmdlet.ParameterSetName) {
            "securestring" {
                $Tmp = New-Object System.Management.Automation.PSCredential -ArgumentList('dummy', $InputSecureString)
            }
            default {
                $Tmp = New-Object System.Management.Automation.PSCredential -ArgumentList('dummy', ($InputString | ConvertTo-SecureString))
            }
        }
        $OutputString = $Tmp.GetNetworkCredential().Password
    }
    End {
        $OutputString | Write-Output
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}
