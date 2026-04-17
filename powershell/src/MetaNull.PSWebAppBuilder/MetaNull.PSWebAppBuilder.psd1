@{
    RootModule        = 'MetaNull.PSWebAppBuilder.psm1'
    ModuleVersion     = '0.1.2'
    GUID              = 'c362c902-0611-49c0-b389-f5ac097ca483'
    Author            = 'Pascal Havelange'
    CompanyName       = 'Museum With No Frontiers'
    Copyright         = '(c) Museum With No Frontiers. All rights reserved.'
    Description       = 'Web application build and deployment pipelines for Laravel, Lumen, and Node.js projects.'
    PowerShellVersion = '5.1'
    RequiredModules   = @(
        @{
            ModuleName = 'MetaNull.PSGitOps'
            ModuleVersion = '0.1.2'
        }
    )
    FunctionsToExport = @(
        'Invoke-WebAppUpdate'
        'Build-LaravelApi'
        'Build-LumenApi'
        'Build-NodeJSClient'
        'Update-GitLatest'
    )
    CmdletsToExport   = @()
    VariablesToExport  = @()
    AliasesToExport    = @()
    PrivateData       = @{
        PSData = @{
            Tags         = @('laravel', 'nodejs', 'deployment', 'devops')
            LicenseUri   = 'https://opensource.org/license/mit'
            ProjectUri   = 'https://github.com/metanull/hooked'
            ReleaseNotes = '0.1.2: Refresh module GUID and continue PSGallery metadata cleanup.'
        }
    }
}
