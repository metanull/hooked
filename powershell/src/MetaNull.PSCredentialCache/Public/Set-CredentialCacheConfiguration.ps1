function Set-CredentialCacheConfiguration {
    <#
        .SYNOPSIS
            Configure the credential cache module settings.
        .DESCRIPTION
            Sets the registry root path and/or cache duration for credential storage.
        .PARAMETER RegistryRoot
            The registry path used as the root for credential storage.
        .PARAMETER CacheDurationMinutes
            The number of minutes before a cached credential expires. Default: 43200 (30 days).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$RegistryRoot,

        [Parameter(Mandatory = $false)]
        [int]$CacheDurationMinutes
    )
    Begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"
    }
    Process {
        if ($PSBoundParameters.ContainsKey('RegistryRoot')) {
            $script:CredentialCacheConfig.RegistryRoot = $RegistryRoot
        }
        if ($PSBoundParameters.ContainsKey('CacheDurationMinutes')) {
            $script:CredentialCacheConfig.CacheDurationMinutes = $CacheDurationMinutes
        }
    }
    End {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}
