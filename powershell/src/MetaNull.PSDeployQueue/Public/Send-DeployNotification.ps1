function Send-DeployNotification {
    <#
        .SYNOPSIS
            Send all queued notifications via email.
        .DESCRIPTION
            Retrieves and sends all queued notifications. With -AsTable, all notifications
            are combined into a single HTML table email. Otherwise each is sent separately.
        .PARAMETER AsTable
            If set, notifications are formatted as an HTML table and sent in one email.
        .PARAMETER To
            Override the recipient list. If not specified, uses Send-DeployMail defaults.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [switch]$AsTable,

        [Parameter(Mandatory = $false)]
        [string[]]$To
    )
    Begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"
        $MutexName = "$($script:DeployQueueConfig.MutexPrefix)_ModifyNotification"
        Write-Verbose "Mutex::New ($MutexName)"
        $Mutex = New-Object System.Threading.Mutex($false, $MutexName) -ErrorAction Stop
    }
    End {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function ended"
        Write-Verbose "Mutex::Dispose"
        $Mutex.Dispose()
    }
    Process {
        Write-Verbose "Mutex::Wait"
        if (-not ($Mutex.WaitOne($script:DeployQueueConfig.MutexTimeout))) {
            Write-Error "Error acquiring Mutex (the system is busy with another operation)"
            return
        }
        try {
            $RegistryKey = Join-Path $script:DeployQueueConfig.RegistryRoot 'Notification'
            if (-not (Test-Path $RegistryKey)) {
                Write-Verbose 'There are no pending notifications'
                return
            }
            $Notification = Get-Item $RegistryKey
            if ($Notification.SubKeyCount -gt 0) {
                $AllNotifications = @(
                    $Notification | Get-ChildItem | Sort-Object Name | ForEach-Object {
                        $ItemToPop = $_
                        $Item = @{}
                        ($ItemToPop | Get-ItemProperty).PSObject.Properties | Where-Object { $_.Name -notmatch '^PS\w+$' } | ForEach-Object { $Item[$_.Name] = $_.Value }
                        if ($Item.ContainsKey('Date')) {
                            $Item.Date = Get-Date -Date $Item.Date
                        }
                        [PSCustomObject]$Item
                        $ItemToPop | Remove-Item
                    }
                )

                $MailParams = @{
                    Subject = 'Deploy Queue Notifications'
                }
                if ($To) {
                    $MailParams['To'] = $To
                }

                if ($AsTable) {
                    $MailParams['Body'] = ($AllNotifications | ConvertTo-Html -Title 'All notifications')
                    Send-DeployMail @MailParams -ErrorAction Stop
                } else {
                    $AllNotifications | ForEach-Object {
                        $MailParams['Body'] = ($_ | ConvertTo-Html -Title 'Notification')
                        Send-DeployMail @MailParams -ErrorAction Stop
                    }
                }
            } else {
                Write-Verbose 'There are no pending notifications'
            }
        } finally {
            Write-Verbose "Mutex::Release"
            $Mutex.ReleaseMutex()
        }
    }
}
