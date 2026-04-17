function Invoke-WebAppUpdate {
    <#
        .SYNOPSIS
            Update a web application by pulling the latest source and running build pipeline steps.
        .DESCRIPTION
            Core deployment pipeline. Fetches the latest code from a git branch, optionally resets
            and pulls, then executes an ordered set of build script blocks. Supports mutex-based
            single-execution guard, progress reporting, logging, and email notifications.

            Ported from Generic-Updater in helpers.ps1, with all paths and recipients parameterized.
        .PARAMETER Directory
            Path to the application working directory.
        .PARAMETER Branch
            Name of the git branch to use.
        .PARAMETER Alias
            Display name for the application (used in progress and notifications).
        .PARAMETER Url
            The application URL (used in notifications for display purposes).
        .PARAMETER ScriptBlock
            An ordered hashtable of named script blocks defining the build pipeline steps.
        .PARAMETER MutexName
            Mutex name for single-execution guard. Default: 'WebAppUpdateMutex'.
        .PARAMETER Force
            If set, always reset and pull. Otherwise, only pull if the branch is behind remote.
        .PARAMETER LogFile
            Path to the log file. If not specified, no file logging is performed.
        .PARAMETER SmtpServer
            SMTP server for email notifications. If not specified, email is skipped.
        .PARAMETER SmtpFrom
            Sender address for email notifications.
        .PARAMETER To
            Recipient(s) for email notifications.
        .PARAMETER Cc
            CC recipient(s) for email notifications.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Directory,

        [Parameter(Mandatory = $true)]
        [string]$Branch,

        [Parameter(Mandatory = $true)]
        [string]$Alias,

        [Parameter(Mandatory = $true)]
        [string]$Url,

        [Parameter(Mandatory = $true)]
        [System.Collections.IDictionary]$ScriptBlock,

        [Parameter(Mandatory = $false)]
        [string]$MutexName = 'WebAppUpdateMutex',

        [Parameter(Mandatory = $false)]
        [switch]$Force,

        [Parameter(Mandatory = $false)]
        [string]$LogFile,

        [Parameter(Mandatory = $false)]
        [string]$SmtpServer,

        [Parameter(Mandatory = $false)]
        [string]$SmtpFrom,

        [Parameter(Mandatory = $false)]
        [string[]]$To,

        [Parameter(Mandatory = $false)]
        [string[]]$Cc
    )
    Begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"
        $OldDirectory = Get-Location

        $PullScriptBlock = [ordered]@{
            Cleaning = {
                Write-Verbose '> Cleaning up!'
                Reset-GitRepository
                Set-GitCurrentBranch -Branch $Branch
                git clean -fd 2>&1
            }
            Fetching = {
                Write-Verbose '> Fetching!'
                git fetch origin $Branch 2>&1
            }
            Pulling = {
                Write-Verbose '> Updating!'
                git reset --hard "origin/$Branch" 2>&1
            }
            Reporting = {
                Write-Verbose '> Reporting!'
                git log --abbrev-commit --decorate --format=format:'%h - (%ar) %s - %an%d' -10
            }
        }

        $Progress = @{
            Activity         = "$Alias ($Url)"
            Status           = 'Updating'
            CurrentOperation = 'Initializing'
            PercentComplete  = 0
        }
        Write-Progress @Progress
    }
    End {
        $Progress.Completed = $true
        Write-Progress @Progress
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Done"
        Set-Location $OldDirectory
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
    Process {
        if ($LogFile) {
            Write-Output "`n$((Get-Date -UFormat '%d/%m/%Y %T'))" | Out-File $LogFile
        }

        $Mutex = New-Object System.Threading.Mutex($false, $MutexName)
        try {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Updating $Alias ($Url)"

            # Wait for mutex
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Waiting for mutex..."
            $Progress.Status = 'Waiting'
            Write-Progress @Progress
            $Mutex.WaitOne() | Out-Null

            # Set working directory
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Entering directory $Directory"
            Set-Location $Directory -ErrorAction Stop

            # Check if update is needed
            $updateNeeded = $false
            if ($Force) {
                $updateNeeded = $true
            } else {
                Sync-GitRepository
                $status = git status 2>$null
                $updateNeeded = ($status | Select-String -Pattern "^Your branch is up to date with 'origin/" | Measure-Object).Count -eq 0
            }

            $Progress.Status = 'Updating'
            Write-Progress @Progress

            # Send start notification
            if ($SmtpServer -and $SmtpFrom -and $To) {
                $mailParams = @{
                    Subject    = "Upgrade started ($Alias)"
                    Body       = "Upgrade of $Url has started"
                    SmtpServer = $SmtpServer
                    From       = $SmtpFrom
                    To         = $To
                    Priority   = 'Low'
                    BodyAsHtml = $true
                }
                Send-MailMessage @mailParams -ErrorAction SilentlyContinue
            }

            $HowManySteps = $ScriptBlock.Count
            if ($updateNeeded) {
                $HowManySteps += $PullScriptBlock.Count
                Write-Verbose "[$($MyInvocation.MyCommand.Name)] Updating code"
                $PullScriptBlock.GetEnumerator() | ForEach-Object {
                    $Progress.CurrentOperation = "Task: $($_.Key)"
                    Write-Progress @Progress

                    $scriptLog = & $_.Value

                    if ($LogFile) {
                        $scriptLog | Out-File -Append $LogFile
                    }

                    $Progress.PercentComplete += [int](100 / $HowManySteps)
                    if ($Progress.PercentComplete -gt 100) { $Progress.PercentComplete = 100 }
                    Write-Progress @Progress
                }
            } else {
                Write-Verbose "[$($MyInvocation.MyCommand.Name)] Code already up-to-date, skipping!"
            }

            # Run build pipeline
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Running pipeline"
            $ScriptBlock.GetEnumerator() | ForEach-Object {
                $Progress.CurrentOperation = "Task: $($_.Key)"
                Write-Progress @Progress

                $scriptLog = & $_.Value

                if ($LogFile) {
                    $scriptLog | Out-File -Append $LogFile
                }

                $Progress.PercentComplete += [int](100 / $HowManySteps)
                if ($Progress.PercentComplete -gt 100) { $Progress.PercentComplete = 100 }
                Write-Progress @Progress
            }

            # Send completion notification
            if ($SmtpServer -and $SmtpFrom -and $To) {
                $mailParams = @{
                    Subject    = "Upgrade complete ($Alias)"
                    Body       = "Upgrade of $Url is complete"
                    SmtpServer = $SmtpServer
                    From       = $SmtpFrom
                    To         = $To
                    Priority   = 'Low'
                    BodyAsHtml = $true
                }
                if ($Cc) { $mailParams['Cc'] = $Cc }
                if ($LogFile -and (Test-Path $LogFile)) {
                    $mailParams.Body += "`n`n" + (Get-Content $LogFile -Raw)
                }
                Send-MailMessage @mailParams -ErrorAction SilentlyContinue
            }
        } catch {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Error occurred!"

            if ($LogFile) {
                "[$($_.Exception.GetType().FullName)]" | Out-File -Append $LogFile
                $_.Exception.Message | Out-File -Append $LogFile
            }

            # Send error notification
            if ($SmtpServer -and $SmtpFrom -and $To) {
                $mailParams = @{
                    Subject    = "Error during upgrade ($Alias)"
                    Body       = "An error occurred during upgrade of $Url`n`nERROR: $($_.Exception.Message)"
                    SmtpServer = $SmtpServer
                    From       = $SmtpFrom
                    To         = $To
                    Priority   = 'High'
                    BodyAsHtml = $true
                }
                Send-MailMessage @mailParams -ErrorAction SilentlyContinue
            }
            throw
        } finally {
            $Mutex.ReleaseMutex()
        }
    }
}
