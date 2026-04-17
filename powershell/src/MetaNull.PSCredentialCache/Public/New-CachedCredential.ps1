function New-CachedCredential {
    <#
        .SYNOPSIS
            Store a credential in the registry-backed cache.
        .DESCRIPTION
            Stores a PSCredential in the DPAPI-encrypted registry cache. The credential can be
            retrieved later with Get-CachedCredential. The cache key is derived from the username hash.
        .PARAMETER UserName
            The username to prompt credentials for.
        .PARAMETER Credential
            A pre-built PSCredential object to cache.
        .PARAMETER RegistryRoot
            Override the registry root for this operation. Defaults to module configuration.
        .PARAMETER Message
            Message to display in the credential prompt dialog.
    #>
    [CmdletBinding(DefaultParameterSetName = 'prompt')]
    [OutputType([pscredential])]
    param(
        [Parameter(ValueFromPipeline = $true, Mandatory = $true, Position = 0, ParameterSetName = 'prompt_credential')]
        [string]$UserName,

        [Parameter(ValueFromPipeline = $true, Mandatory = $true, Position = 0, ParameterSetName = 'credential_provided')]
        [pscredential]$Credential,

        [Parameter(Mandatory = $false, Position = 1, ParameterSetName = 'prompt_credential')]
        [Parameter(Mandatory = $false, Position = 1, ParameterSetName = 'credential_provided')]
        [Parameter(Mandatory = $false, Position = 0, ParameterSetName = 'prompt')]
        [string]$RegistryRoot,

        [Parameter(Mandatory = $true, Position = 2, ParameterSetName = 'prompt_credential')]
        [string]$Message
    )
    Begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"
        [pscredential]$OutputCredential = [System.Management.Automation.PSCredential]::Empty
    }
    Process {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        switch ($PsCmdlet.ParameterSetName) {
            "prompt" {
                $InputCredential = Get-Credential
            }
            "prompt_credential" {
                $params = @{}
                if ($PSBoundParameters.ContainsKey('UserName')) { $params['UserName'] = $UserName }
                if ($PSBoundParameters.ContainsKey('Message')) { $params['Message'] = $Message }
                $InputCredential = Get-Credential @params
                if ($InputCredential.UserName -eq $PSBoundParameters.UserName -and $InputCredential.UserName -cne $PSBoundParameters.UserName) {
                    Write-Warning "Get-Credential replaced the value of `$UserName = '$($PSBoundParameters.UserName)' with '$($InputCredential.UserName)'."
                }
            }
            "credential_provided" {
                $InputCredential = $Credential
            }
        }
        if ($null -eq $InputCredential -or $InputCredential -eq [System.Management.Automation.PSCredential]::Empty) {
            throw "Invalid/Empty credentials received."
        }
        $OutputCredential = $InputCredential

        if ([string]::IsNullOrEmpty($RegistryRoot)) {
            $RegistryRoot = $script:CredentialCacheConfig.RegistryRoot
        }
        $RegistryKey = "{0}\Credential\{1}" -f $RegistryRoot, (ConvertTo-Hash $InputCredential.UserName)

        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Creating Registry Key: $($RegistryKey)"
        New-Item -Path $RegistryKey -ErrorAction Stop -Force | Out-Null
        New-ItemProperty -Path $RegistryKey -PropertyType String -Name UserName -Value $InputCredential.UserName | Out-Null
        New-ItemProperty -Path $RegistryKey -PropertyType String -Name Password -Value ($InputCredential.Password | ConvertFrom-SecureString) | Out-Null
        New-ItemProperty -Path $RegistryKey -PropertyType String -Name Domain -Value $InputCredential.GetNetworkCredential().Domain | Out-Null
        New-ItemProperty -Path $RegistryKey -PropertyType String -Name DomainUserName -Value $InputCredential.GetNetworkCredential().UserName | Out-Null
        New-ItemProperty -Path $RegistryKey -PropertyType String -Name LastUpdate -Value (Get-Date -Format 'yyyyMMddHHmmss') | Out-Null
    }
    End {
        $OutputCredential
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}
