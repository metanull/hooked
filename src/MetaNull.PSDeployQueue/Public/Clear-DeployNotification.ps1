function Clear-DeployNotification {
    <#
        .SYNOPSIS
            Clear and return all queued notifications.
        .DESCRIPTION
            Removes all notifications from the registry-backed queue and returns them.
            Protected by a mutex.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject[]])]
    param()
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
                return
            }
            $Notification = Get-Item $RegistryKey
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
        } finally {
            Write-Verbose "Mutex::Release"
            $Mutex.ReleaseMutex()
        }
    }
}
