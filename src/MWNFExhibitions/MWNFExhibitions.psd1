@{
    RootModule        = 'MWNFExhibitions.psm1'
    ModuleVersion     = '0.1.0'
    GUID              = 'ef221aa6-2050-4486-b59a-88e8bd1e1f0a'
    Author            = 'Pascal Havelange'
    CompanyName       = 'Museum With No Frontiers'
    Copyright         = '(c) Museum With No Frontiers. All rights reserved.'
    Description       = 'MWNF exhibition management wrappers built on top of the published MetaNull PowerShell modules.'
    PowerShellVersion = '5.1'
    CompatiblePSEditions = @('Desktop')
    RequiredModules   = @(
        @{ ModuleName = 'MetaNull.PSStringToolkit'; ModuleVersion = '0.1.2' }
        @{ ModuleName = 'MetaNull.PSGitOps'; ModuleVersion = '0.1.2' }
        @{ ModuleName = 'MetaNull.PSCredentialCache'; ModuleVersion = '0.1.2' }
        @{ ModuleName = 'MetaNull.PSDeployQueue'; ModuleVersion = '0.1.2' }
        @{ ModuleName = 'MetaNull.PSWebAppBuilder'; ModuleVersion = '0.1.2' }
    )
    FunctionsToExport = @(
        'Test-ExhibitionName'
        'Test-LanguageId'
        'Import-ExhibitionServerConfiguration'
        'Set-ExhibitionServerDatabaseCredential'
        'Install-Exhibition'
        'Uninstall-Exhibition'
        'Get-Exhibition'
        'Publish-Exhibition'
        'Unpublish-Exhibition'
    )
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
    PrivateData       = @{
        PSData = @{
            Tags         = @('mwnf', 'exhibitions', 'deployment', 'registry', 'wrapper')
            LicenseUri   = 'https://opensource.org/licenses/MIT'
            ProjectUri   = 'https://github.com/metanull/hooked'
            ReleaseNotes = '0.1.0: Initial MWNFExhibitions wrapper module for Phase 2 (M06/E06).'
        }
    }
}