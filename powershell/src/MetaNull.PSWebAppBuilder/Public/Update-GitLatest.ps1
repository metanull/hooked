function Update-GitLatest {
    <#
        .SYNOPSIS
            Pull the latest source code without running any build steps.
        .DESCRIPTION
            Wraps Invoke-WebAppUpdate with a no-op script block, performing only
            the git fetch/reset/pull cycle. Useful for repositories that need code
            updates without a build pipeline.
        .PARAMETER Directory
            Path to the application directory.
        .PARAMETER Branch
            Git branch name.
        .PARAMETER Alias
            Display name for the application.
        .PARAMETER Url
            The application URL (for display purposes).
        .PARAMETER MutexName
            Mutex name for single-execution guard.
        .PARAMETER Force
            If set, always reset and pull.
        .PARAMETER LogFile
            Path to the log file.
        .PARAMETER SmtpServer
            SMTP server for notifications.
        .PARAMETER SmtpFrom
            Sender address for notifications.
        .PARAMETER To
            Recipient(s) for notifications.
        .PARAMETER Cc
            CC recipient(s) for notifications.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]  [string]$Directory,
        [Parameter(Mandatory = $true)]  [string]$Branch,
        [Parameter(Mandatory = $true)]  [string]$Alias,
        [Parameter(Mandatory = $true)]  [string]$Url,
        [Parameter(Mandatory = $false)] [string]$MutexName = 'WebAppUpdateMutex',
        [Parameter(Mandatory = $false)] [switch]$Force,
        [Parameter(Mandatory = $false)] [string]$LogFile,
        [Parameter(Mandatory = $false)] [string]$SmtpServer,
        [Parameter(Mandatory = $false)] [string]$SmtpFrom,
        [Parameter(Mandatory = $false)] [string[]]$To,
        [Parameter(Mandatory = $false)] [string[]]$Cc
    )
    Process {
        $arguments = @{}
        foreach ($key in $PSBoundParameters.Keys) { $arguments[$key] = $PSBoundParameters[$key] }
        $arguments['ScriptBlock'] = [ordered]@{
            NothingToDo = {
                Write-Verbose '> Done!'
            }
        }
        Invoke-WebAppUpdate @arguments
    }
}
