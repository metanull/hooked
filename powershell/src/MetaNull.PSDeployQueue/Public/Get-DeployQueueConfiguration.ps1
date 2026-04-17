function Get-DeployQueueConfiguration {
    <#
        .SYNOPSIS
            Retrieve the current deploy queue module settings.
        .DESCRIPTION
            Returns the current configuration including registry root, mutex settings,
            Task Scheduler settings, and launcher script path.
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param()
    Begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"
    }
    Process {
        @{
            RegistryRoot      = $script:DeployQueueConfig.RegistryRoot
            MutexPrefix       = $script:DeployQueueConfig.MutexPrefix
            MutexTimeout      = $script:DeployQueueConfig.MutexTimeout
            TaskSchedulerPath = $script:DeployQueueConfig.TaskSchedulerPath
            TaskSchedulerName = $script:DeployQueueConfig.TaskSchedulerName
            LauncherScript    = $script:DeployQueueConfig.LauncherScript
        }
    }
    End {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}
