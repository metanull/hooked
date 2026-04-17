function Test-CachedCredential {
    <#
        .SYNOPSIS
            Test whether a cached credential exists and is valid.
        .DESCRIPTION
            Returns $true if a non-expired cached credential exists for the given username,
            $false otherwise. Use -NoExpiration to ignore the expiry check.
        .PARAMETER UserName
            The username to test.
        .PARAMETER RegistryRoot
            Override the registry root for this operation. Defaults to module configuration.
        .PARAMETER NoExpiration
            If set, returns $true as long as the credential exists, regardless of age.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(ValueFromPipeline = $true, Mandatory = $true, Position = 0)]
        [string]$UserName,

        [Parameter(Mandatory = $false, Position = 1)]
        [string]$RegistryRoot,

        [Parameter(Mandatory = $false)]
        [switch]$NoExpiration
    )
    Begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"
        [bool]$OutputBool = $false
    }
    Process {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        $CredentialCacheDuration = $script:CredentialCacheConfig.CacheDurationMinutes
        if ([string]::IsNullOrEmpty($RegistryRoot)) {
            $RegistryRoot = $script:CredentialCacheConfig.RegistryRoot
        }
        $RegistryKey = "{0}\Credential\{1}" -f $RegistryRoot, (ConvertTo-Hash $UserName)

        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Reading Registry Key: $($RegistryKey)"
        $Properties = Get-ItemProperty -Path $RegistryKey -ErrorAction SilentlyContinue
        if ($NoExpiration) {
            if ($null -ne $Properties) {
                $OutputBool = $true
            } else {
                $OutputBool = $false
            }
        } elseif ($Properties -and -not (Test-IsExpired -DateString $Properties.LastUpdate -Minutes $CredentialCacheDuration)) {
            $OutputBool = $true
        } else {
            $OutputBool = $false
        }
    }
    End {
        $OutputBool
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}
