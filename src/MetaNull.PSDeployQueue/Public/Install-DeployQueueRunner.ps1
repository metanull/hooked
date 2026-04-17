function Install-DeployQueueRunner {
    <#
        .SYNOPSIS
            Install a scheduled task to run the deploy queue asynchronously.
        .DESCRIPTION
            Registers a scheduled task in Windows Task Scheduler that invokes the queue runner.
            The task path and name are configurable via Set-DeployQueueConfiguration.
    #>
    [CmdletBinding()]
    param()
    Begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"
        $LauncherScript = $script:DeployQueueConfig.LauncherScript
        if ([string]::IsNullOrEmpty($LauncherScript)) {
            throw "LauncherScript is not configured. Use Set-DeployQueueConfiguration -LauncherScript <path> first."
        }
        Write-Verbose "LauncherScript: $LauncherScript"
    }
    End {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
    Process {
        Register-QueueScheduledTask -LauncherScript $LauncherScript -TaskPath $script:DeployQueueConfig.TaskSchedulerPath -TaskName $script:DeployQueueConfig.TaskSchedulerName
    }
}
