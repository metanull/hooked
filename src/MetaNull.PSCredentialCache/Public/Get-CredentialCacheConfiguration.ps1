function Get-CredentialCacheConfiguration {
    <#
        .SYNOPSIS
            Retrieve the current credential cache module settings.
        .DESCRIPTION
            Returns the current registry root path and cache duration configuration.
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param()
    Begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"
    }
    Process {
        @{
            RegistryRoot = $script:CredentialCacheConfig.RegistryRoot
            CacheDurationMinutes = $script:CredentialCacheConfig.CacheDurationMinutes
        }
    }
    End {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}
