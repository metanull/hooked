# MetaNull.PSDeployQueue
# Registry-backed deployment queue with mutex concurrency, Task Scheduler runner, and notification pipeline.

# Module-scoped configuration defaults
$script:DeployQueueConfig = @{
    RegistryRoot       = 'HKLM:\SOFTWARE\MetaNull.PSDeployQueue'
    MutexPrefix        = 'MetaNull.PSDeployQueue'
    MutexTimeout       = 1000
    TaskSchedulerPath  = '\MetaNull.PSDeployQueue\'
    TaskSchedulerName  = 'RunQueue'
    LauncherScript     = $null
}

$Public = @(Get-ChildItem -Path "$PSScriptRoot\Public\*.ps1" -ErrorAction SilentlyContinue)
$Private = @(Get-ChildItem -Path "$PSScriptRoot\Private\*.ps1" -ErrorAction SilentlyContinue)

foreach ($import in @($Public + $Private)) {
    try {
        . $import.FullName
    } catch {
        Write-Error "Failed to import function $($import.FullName): $_"
    }
}

Export-ModuleMember -Function $Public.BaseName
