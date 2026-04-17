@{
    RootModule        = 'MetaNull.PSCredentialCache.psm1'
    ModuleVersion     = '0.1.0'
    GUID              = 'c3d4e5f6-a7b8-4c9d-0e1f-2a3b4c5d6e7f'
    Author            = 'Pascal Havelange'
    CompanyName       = 'Museum With No Frontiers'
    Copyright         = '(c) Museum With No Frontiers. All rights reserved.'
    Description       = 'DPAPI credential caching with configurable registry storage and expiry. Windows-only.'
    PowerShellVersion = '5.1'
    CompatiblePSEditions = @('Desktop')
    RequiredModules   = @('MetaNull.PSStringToolkit')
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
            Tags       = @('credential', 'dpapi', 'windows', 'security')
            LicenseUri = 'https://github.com/metanull/hooked/blob/main/LICENSE'
            ProjectUri = 'https://github.com/metanull/hooked'
        }
    }
}
