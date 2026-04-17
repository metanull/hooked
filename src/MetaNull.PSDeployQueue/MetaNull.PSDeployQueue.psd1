@{
    RootModule        = 'MetaNull.PSDeployQueue.psm1'
    ModuleVersion     = '0.1.0'
    GUID              = 'd4e5f6a7-b8c9-4d0e-1f2a-3b4c5d6e7f80'
    Author            = 'Pascal Havelange'
    CompanyName       = 'Museum With No Frontiers'
    Copyright         = '(c) Museum With No Frontiers. All rights reserved.'
    Description       = 'Registry-backed deployment queue with mutex concurrency, Task Scheduler runner, and notification pipeline.'
    PowerShellVersion = '5.1'
    FunctionsToExport = @(
        'Set-DeployQueueConfiguration'
        'Get-DeployQueueConfiguration'
        'Push-DeployQueue'
        'Pop-DeployQueue'
        'Get-DeployQueue'
        'Clear-DeployQueue'
        'Invoke-DeployQueue'
        'Test-DeployQueue'
        'Install-DeployQueueRunner'
        'Uninstall-DeployQueueRunner'
        'Start-DeployQueueRunner'
        'Get-DeployQueueRunner'
        'Get-DeployQueueRunnerState'
        'Push-DeployNotification'
        'Pop-DeployNotification'
        'Get-DeployNotification'
        'Clear-DeployNotification'
        'Send-DeployNotification'
        'Send-DeployMail'
    )
    CmdletsToExport   = @()
    VariablesToExport  = @()
    AliasesToExport    = @()
    PrivateData       = @{
        PSData = @{
            Tags       = @('queue', 'deployment', 'scheduler', 'notification', 'devops')
            LicenseUri = 'https://github.com/metanull/hooked/blob/main/LICENSE'
            ProjectUri = 'https://github.com/metanull/hooked'
        }
    }
}
