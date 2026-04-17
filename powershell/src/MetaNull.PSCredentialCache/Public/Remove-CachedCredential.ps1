function Remove-CachedCredential {
    <#
        .SYNOPSIS
            Remove a credential from the registry-backed cache.
        .DESCRIPTION
            Deletes the cached credential for the given username from the registry.
        .PARAMETER UserName
            The username whose cached credential to remove.
        .PARAMETER RegistryRoot
            Override the registry root for this operation. Defaults to module configuration.
    #>
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true, Mandatory = $true, Position = 0)]
        [string]$UserName,

        [Parameter(Mandatory = $false, Position = 1)]
        [string]$RegistryRoot
    )
    Begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"
    }
    Process {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        if ([string]::IsNullOrEmpty($RegistryRoot)) {
            $RegistryRoot = $script:CredentialCacheConfig.RegistryRoot
        }
        $RegistryKey = "{0}\Credential\{1}" -f $RegistryRoot, (ConvertTo-Hash $UserName)

        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Removing Registry Key: $($RegistryKey)"
        Remove-Item -Path $RegistryKey -ErrorAction Continue -Force
    }
    End {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}
