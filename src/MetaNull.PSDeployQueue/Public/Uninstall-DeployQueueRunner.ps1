function Uninstall-DeployQueueRunner {
    <#
        .SYNOPSIS
            Uninstall the scheduled task for the deploy queue runner.
        .DESCRIPTION
            Removes the scheduled task that runs the deploy queue asynchronously.
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
        Unregister-ScheduledTask -TaskPath $script:DeployQueueConfig.TaskSchedulerPath -TaskName $script:DeployQueueConfig.TaskSchedulerName -Confirm:$false
    }
}
