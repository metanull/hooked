function Get-DeployQueueRunnerState {
    <#
        .SYNOPSIS
            Get the state of the deploy queue runner scheduled task.
        .DESCRIPTION
            Returns the human-readable state of the queue runner task (Unknown, Disabled, Queued, Ready, Running).
        .EXAMPLE
            if ('Ready' -eq (Get-DeployQueueRunnerState)) { 'Queue is idle' }
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param()
    Begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"
        $Task = Get-DeployQueueRunner
    }
    End {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
    Process {
        $States = @('Unknown', 'Disabled', 'Queued', 'Ready', 'Running')
        $States[$Task.State]
    }
}
