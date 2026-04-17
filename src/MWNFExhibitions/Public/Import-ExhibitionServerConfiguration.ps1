function Import-ExhibitionServerConfiguration {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $registryRoot = Initialize-ExhibitionServerRegistry
    $exhibitionsRoot = Join-Path $registryRoot 'Exhibitions'
    $exhibitions = @()

    if (Test-Path -Path $exhibitionsRoot) {
        $exhibitions = Get-ChildItem -Path $exhibitionsRoot -ErrorAction Stop | ForEach-Object {
            [pscustomobject]@{
                Name              = (Get-ItemPropertyValue -Path $_.PSPath -Name 'Name' -ErrorAction Stop)
                LanguageId        = (Get-ItemPropertyValue -Path $_.PSPath -Name 'LanguageId' -ErrorAction Stop)
                Status            = (Get-ItemPropertyValue -Path $_.PSPath -Name 'Status' -ErrorAction SilentlyContinue)
                ApiEnvironment    = Get-RegistryValueSet -Path (Join-Path $_.PSPath 'ApiEnvironment')
                ClientEnvironment = Get-RegistryValueSet -Path (Join-Path $_.PSPath 'ClientEnvironment')
                Path              = $_.PSPath
            }
        }
    }

    return [pscustomobject]@{
        Date              = Get-Date
        Path              = $registryRoot
        HiveSettings      = Get-RegistryValueSet -Path (Join-Path $script:MWNFExhibitionsConfig.RegistryHive 'Settings')
        Settings          = Get-RegistryValueSet -Path (Join-Path $registryRoot 'Settings')
        Exhibitions       = $exhibitions
        ApiEnvironment    = Get-RegistryValueSet -Path (Join-Path $registryRoot 'Settings\ApiEnvironment')
        ClientEnvironment = Get-RegistryValueSet -Path (Join-Path $registryRoot 'Settings\ClientEnvironment')
    }
}