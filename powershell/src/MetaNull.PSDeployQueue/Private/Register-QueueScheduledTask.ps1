function Register-QueueScheduledTask {
    <#
        .SYNOPSIS
            Register the queue runner scheduled task (internal helper).
        .DESCRIPTION
            Wraps Task Scheduler cmdlets for testability. CIM-typed dynamic parameters
            on ScheduledTask cmdlets cannot be reliably mocked with -RemoveParameterType,
            so this helper encapsulates the entire chain.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$LauncherScript,

        [Parameter(Mandatory = $true)]
        [string]$TaskPath,

        [Parameter(Mandatory = $true)]
        [string]$TaskName
    )
    Process {
        $Action = New-ScheduledTaskAction -Execute 'powershell' -Argument ('-noninteractive -nologo -file {0} Invoke-DeployQueue' -f $LauncherScript)
        $Trigger = New-ScheduledTaskTrigger -Daily -At 2am
        $Settings = New-ScheduledTaskSettingsSet
        $Task = New-ScheduledTask -Action $Action -Trigger $Trigger -Settings $Settings
        Register-ScheduledTask -TaskPath $TaskPath -TaskName $TaskName -InputObject $Task
    }
}
