function Clear-DeployQueue {
    <#
        .SYNOPSIS
            Clear the deploy queue and return all removed commands.
        .DESCRIPTION
            Removes all commands from the registry-backed queue and returns them to the caller.
            Queue operations are protected by a mutex.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject[]])]
    param()
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
            ($Queue | Get-ItemProperty).PSObject.Properties | Where-Object { $_.Name -match '^\d+$' } | Select-Object -Property Name, Value | ForEach-Object {
                $Queue | Remove-ItemProperty -Name $_.Name -ErrorAction Stop
                $_
            }
        } finally {
            Write-Verbose "Mutex::Release"
            $Mutex.ReleaseMutex()
        }
    }
}
