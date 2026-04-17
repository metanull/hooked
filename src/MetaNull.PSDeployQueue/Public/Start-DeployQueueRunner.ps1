function Start-DeployQueueRunner {
    <#
        .SYNOPSIS
            Trigger the deploy queue runner scheduled task.
        .DESCRIPTION
            Starts the scheduled task that processes the deploy queue asynchronously.
            The task path and name are configurable via Set-DeployQueueConfiguration.
    #>
    [CmdletBinding()]
    param()
    Begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"
    }
    End {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
    Process {
        Start-ScheduledTask -TaskPath $script:DeployQueueConfig.TaskSchedulerPath -TaskName $script:DeployQueueConfig.TaskSchedulerName
    }
}
