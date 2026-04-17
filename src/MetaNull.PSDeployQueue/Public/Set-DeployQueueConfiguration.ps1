function Set-DeployQueueConfiguration {
    <#
        .SYNOPSIS
            Configure the deploy queue module settings.
        .DESCRIPTION
            Sets registry root, mutex prefix, timeout, Task Scheduler path/name, and launcher script path.
        .PARAMETER RegistryRoot
            The registry path used as the root for queue and notification storage.
        .PARAMETER MutexPrefix
            The prefix for mutex names used by queue operations.
        .PARAMETER MutexTimeout
            The timeout in milliseconds when waiting for a mutex. Default: 1000.
        .PARAMETER TaskSchedulerPath
            The Task Scheduler folder path for the queue runner task.
        .PARAMETER TaskSchedulerName
            The Task Scheduler task name for the queue runner.
        .PARAMETER LauncherScript
            The path to the launcher script executed by the queue runner task.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$RegistryRoot,

        [Parameter(Mandatory = $false)]
        [string]$MutexPrefix,

        [Parameter(Mandatory = $false)]
        [int]$MutexTimeout,

        [Parameter(Mandatory = $false)]
        [string]$TaskSchedulerPath,

        [Parameter(Mandatory = $false)]
        [string]$TaskSchedulerName,

        [Parameter(Mandatory = $false)]
        [string]$LauncherScript
    )
    Begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"
    }
    Process {
        if ($PSBoundParameters.ContainsKey('RegistryRoot')) {
            $script:DeployQueueConfig.RegistryRoot = $RegistryRoot
        }
        if ($PSBoundParameters.ContainsKey('MutexPrefix')) {
            $script:DeployQueueConfig.MutexPrefix = $MutexPrefix
        }
        if ($PSBoundParameters.ContainsKey('MutexTimeout')) {
            $script:DeployQueueConfig.MutexTimeout = $MutexTimeout
        }
        if ($PSBoundParameters.ContainsKey('TaskSchedulerPath')) {
            $script:DeployQueueConfig.TaskSchedulerPath = $TaskSchedulerPath
        }
        if ($PSBoundParameters.ContainsKey('TaskSchedulerName')) {
            $script:DeployQueueConfig.TaskSchedulerName = $TaskSchedulerName
        }
        if ($PSBoundParameters.ContainsKey('LauncherScript')) {
            $script:DeployQueueConfig.LauncherScript = $LauncherScript
        }
    }
    End {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}
