function Get-DeployNotification {
    <#
        .SYNOPSIS
            Retrieve all queued notification messages.
        .DESCRIPTION
            Returns all notifications currently in the registry-backed notification queue.
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
                $Item = @{}
                ($_ | Get-ItemProperty).PSObject.Properties | Where-Object { $_.Name -notmatch '^PS\w+$' } | ForEach-Object { $Item[$_.Name] = $_.Value }
                if ($Item.ContainsKey('Date')) {
                    $Item.Date = Get-Date -Date $Item.Date
                }
                [PSCustomObject]$Item
            }
        } finally {
            Write-Verbose "Mutex::Release"
            $Mutex.ReleaseMutex()
        }
    }
}
