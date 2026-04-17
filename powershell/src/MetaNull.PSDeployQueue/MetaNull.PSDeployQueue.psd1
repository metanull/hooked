@{
    RootModule        = 'MetaNull.PSDeployQueue.psm1'
    ModuleVersion     = '0.1.2'
    GUID              = '7802d35e-760c-4129-a22a-a4e7e0a59eb9'
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
            Tags         = @('queue', 'deployment', 'scheduler', 'notification', 'devops')
            LicenseUri   = 'https://opensource.org/license/mit'
            ProjectUri   = 'https://github.com/metanull/hooked'
            ReleaseNotes = '0.1.2: Refresh module GUID and continue PSGallery metadata cleanup.'
        }
    }
}
