@{
    RootModule        = 'MetaNull.PSGitOps.psm1'
    ModuleVersion     = '0.1.0'
    GUID              = 'b2c3d4e5-f6a7-4b8c-9d0e-1f2a3b4c5d6e'
    Author            = 'Pascal Havelange'
    CompanyName       = 'Museum With No Frontiers'
    Copyright         = '(c) Museum With No Frontiers. All rights reserved.'
    Description       = 'Git operations for CI/CD pipelines: clone, fetch, reset, checkout, pull, branch info, and repository introspection.'
    PowerShellVersion = '5.1'
    FunctionsToExport = @(
        'Import-GitRepository'
        'Sync-GitRepository'
        'Reset-GitRepository'
        'Set-GitCurrentBranch'
        'Update-GitCurrentBranch'
        'Get-GitCurrentBranch'
        'Get-GitRepository'
    )
    CmdletsToExport   = @()
    VariablesToExport  = @()
    AliasesToExport    = @()
    PrivateData       = @{
        PSData = @{
            Tags       = @('git', 'devops', 'ci-cd', 'deployment')
            LicenseUri = 'https://github.com/metanull/hooked/blob/main/LICENSE'
            ProjectUri = 'https://github.com/metanull/hooked'
        }
    }
}
