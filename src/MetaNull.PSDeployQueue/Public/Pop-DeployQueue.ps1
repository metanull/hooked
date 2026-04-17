function Pop-DeployQueue {
    <#
        .SYNOPSIS
            Pop a command from the queue.
        .DESCRIPTION
            Extracts and returns the last (or first with -Unshift) command from the registry-backed queue.
            Queue operations are protected by a mutex.
        .PARAMETER Unshift
            If set, the first command is extracted instead of the last (FIFO instead of LIFO).
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $false)]
        [switch]$Unshift
    )
    Begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"
        $MutexName = "$($script:DeployQueueConfig.MutexPrefix)_ModifyQueue"
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
            $RegistryKey = Join-Path $script:DeployQueueConfig.RegistryRoot 'Queue'
            if (-not (Test-Path $RegistryKey)) {
                return
            }
            $Queue = Get-Item $RegistryKey
            if ($Queue) {
                if ($Unshift) {
                    $Item = ($Queue | Get-ItemProperty).PSObject.Properties | Where-Object { $_.Name -match '^\d+$' } | Select-Object -First 1 -Property Name, Value
                } else {
                    $Item = ($Queue | Get-ItemProperty).PSObject.Properties | Where-Object { $_.Name -match '^\d+$' } | Select-Object -Last 1 -Property Name, Value
                }
                if ($Item) {
                    $Queue | Remove-ItemProperty -Name $Item.Name
                    return $Item
                }
            }
        } finally {
            Write-Verbose "Mutex::Release"
            $Mutex.ReleaseMutex()
        }
    }
}
