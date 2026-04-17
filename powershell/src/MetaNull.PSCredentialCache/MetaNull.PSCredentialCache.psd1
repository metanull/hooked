@{
    RootModule        = 'MetaNull.PSCredentialCache.psm1'
    ModuleVersion     = '0.1.2'
    GUID              = '832e7476-4ce8-4a88-a77b-686846074eab'
    Author            = 'Pascal Havelange'
    CompanyName       = 'Museum With No Frontiers'
    Copyright         = '(c) Museum With No Frontiers. All rights reserved.'
    Description       = 'DPAPI credential caching with configurable registry storage and expiry. Windows-only.'
    PowerShellVersion = '5.1'
    CompatiblePSEditions = @('Desktop')
    RequiredModules   = @(
        @{
            ModuleName = 'MetaNull.PSStringToolkit'
            ModuleVersion = '0.1.2'
        }
    )
    FunctionsToExport = @(
        'Set-CredentialCacheConfiguration'
        'Get-CredentialCacheConfiguration'
        'Protect-String'
        'Unprotect-String'
        'New-CachedCredential'
        'Get-CachedCredential'
        'Test-CachedCredential'
        'Remove-CachedCredential'
    )
    CmdletsToExport   = @()
    VariablesToExport  = @()
    AliasesToExport    = @()
    PrivateData       = @{
        PSData = @{
            Tags         = @('credential', 'dpapi', 'windows', 'security')
            LicenseUri   = 'https://opensource.org/license/mit'
            ProjectUri   = 'https://github.com/metanull/hooked'
            ReleaseNotes = '0.1.2: Refresh module GUID and continue PSGallery metadata cleanup.'
        }
    }
}
