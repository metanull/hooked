@{
    RootModule        = 'MetaNull.PSGitOps.psm1'
    ModuleVersion     = '0.1.2'
    GUID              = 'aa2c69a8-1887-4ab2-ac6a-ab7f5be82307'
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
            Tags         = @('git', 'devops', 'ci-cd', 'deployment')
            LicenseUri   = 'https://opensource.org/license/mit'
            ProjectUri   = 'https://github.com/metanull/hooked'
            ReleaseNotes = '0.1.2: Refresh module GUID and continue PSGallery metadata cleanup.'
        }
    }
}
