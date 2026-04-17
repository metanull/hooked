function Get-CachedCredential {
    <#
        .SYNOPSIS
            Retrieve a credential from the registry-backed cache.
        .DESCRIPTION
            Retrieves a previously cached PSCredential from the DPAPI-encrypted registry cache.
            If the credential has expired (based on CacheDurationMinutes), an error is written
            unless -NoExpiration is specified.
        .PARAMETER UserName
            The username whose cached credential to retrieve.
        .PARAMETER RegistryRoot
            Override the registry root for this operation. Defaults to module configuration.
        .PARAMETER NoExpiration
            If set, the credential is returned regardless of its age.
    #>
    [CmdletBinding()]
    [OutputType([pscredential])]
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
        [pscredential]$OutputCredential = [System.Management.Automation.PSCredential]::Empty
    }
    Process {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        $CredentialCacheDuration = $script:CredentialCacheConfig.CacheDurationMinutes
        if ([string]::IsNullOrEmpty($RegistryRoot)) {
            $RegistryRoot = $script:CredentialCacheConfig.RegistryRoot
        }
        $RegistryKey = "{0}\Credential\{1}" -f $RegistryRoot, (ConvertTo-Hash $UserName)

        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Reading Registry Key: $($RegistryKey)"
        $Properties = Get-ItemProperty -Path $RegistryKey -ErrorAction Stop

        $CacheCredential = New-Object System.Management.Automation.PSCredential -ArgumentList ($Properties.UserName, ($Properties.Password | ConvertTo-SecureString)) -ErrorAction Stop
        if ($NoExpiration) {
            $OutputCredential = $CacheCredential
        } elseif (-not (Test-IsExpired -DateString $Properties.LastUpdate -Minutes $CredentialCacheDuration)) {
            $OutputCredential = $CacheCredential
            Set-ItemProperty -Path $RegistryKey -Name LastUpdate -Value (Get-Date -Format 'yyyyMMddHHmmss') | Out-Null
        } else {
            Write-Error "CachedCredential not found or expired."
        }
    }
    End {
        $OutputCredential
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}
