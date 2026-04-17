function Pop-DeployNotification {
    <#
        .SYNOPSIS
            Pop a notification from the notification queue.
        .DESCRIPTION
            Extracts and returns the last (or first with -Unshift) notification from the queue.
            Protected by a mutex.
        .PARAMETER Unshift
            If set, the first notification is extracted instead of the last.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $false)]
        [switch]$Unshift
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
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
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
            if ($Notification) {
                if ($Unshift) {
                    $ItemToPop = ($Notification | Get-ChildItem | Sort-Object Name) | Select-Object -First 1
                } else {
                    $ItemToPop = ($Notification | Get-ChildItem | Sort-Object Name) | Select-Object -Last 1
                }
                if ($ItemToPop) {
                    $Item = @{}
                    ($ItemToPop | Get-ItemProperty).PSObject.Properties | Where-Object { $_.Name -notmatch '^PS\w+$' } | ForEach-Object { $Item[$_.Name] = $_.Value }
                    if ($Item.ContainsKey('Date')) {
                        $Item.Date = Get-Date -Date $Item.Date
                    }
                    $ItemToPop | Remove-Item
                    return [PSCustomObject]$Item
                }
            }
        } finally {
            Write-Verbose "Mutex::Release"
            $Mutex.ReleaseMutex()
        }
    }
}
