function Get-DeployQueueRunner {
    <#
        .SYNOPSIS
            Get the scheduled task used to run the deploy queue.
        .DESCRIPTION
            Returns the ScheduledTask object for the queue runner from Windows Task Scheduler.
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
        Get-ScheduledTask -TaskPath $script:DeployQueueConfig.TaskSchedulerPath -TaskName $script:DeployQueueConfig.TaskSchedulerName
    }
}
