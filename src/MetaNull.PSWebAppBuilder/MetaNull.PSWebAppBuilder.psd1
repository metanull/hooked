@{
    RootModule        = 'MetaNull.PSWebAppBuilder.psm1'
    ModuleVersion     = '0.1.0'
    GUID              = 'd4e5f6a7-b8c9-4d0e-1f2a-3b4c5d6e7f80'
    Author            = 'Pascal Havelange'
    CompanyName       = 'Museum With No Frontiers'
    Copyright         = '(c) Museum With No Frontiers. All rights reserved.'
    Description       = 'Web application build and deployment pipelines for Laravel, Lumen, and Node.js projects.'
    PowerShellVersion = '5.1'
    RequiredModules   = @(
        @{
            ModuleName = 'MetaNull.PSGitOps'
            ModuleVersion = '0.1.0'
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
            Tags       = @('laravel', 'nodejs', 'deployment', 'devops')
            LicenseUri = 'https://github.com/metanull/hooked/blob/main/LICENSE'
            ProjectUri = 'https://github.com/metanull/hooked'
        }
    }
}
