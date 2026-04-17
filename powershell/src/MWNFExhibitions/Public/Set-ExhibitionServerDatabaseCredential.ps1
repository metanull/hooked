function Set-ExhibitionServerDatabaseCredential {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [pscredential]$Credential,

        [Parameter(Mandatory = $false, Position = 1)]
        [string]$DatabaseName = 'mwnf3'
    )

    process {
        $registryRoot = Initialize-ExhibitionServerRegistry
        $settingsPath = Join-Path $registryRoot 'Settings'
        if (-not (Test-Path -Path $settingsPath)) {
            New-Item -Path $settingsPath -ItemType Directory -Force | Out-Null
        }

        $plainTextPassword = $Credential.GetNetworkCredential().Password
        $encryptedPassword = Protect-String -InputString $plainTextPassword

        Set-ItemProperty -Path $settingsPath -Name 'DatabaseUsername' -Value $Credential.UserName -ErrorAction Stop
        Set-ItemProperty -Path $settingsPath -Name 'DatabasePassword' -Value $encryptedPassword -ErrorAction Stop
        Set-ItemProperty -Path $settingsPath -Name 'DatabaseName' -Value $DatabaseName -ErrorAction Stop
    }
}