function Invoke-DeployQueue {
    <#
        .SYNOPSIS
            Execute all commands in the deploy queue inline.
        .DESCRIPTION
            Pops and executes all commands from the queue sequentially. Uses the execute mutex
            to ensure only one execution runs at a time. On error, sends a notification email
            and re-throws.
    #>
    [CmdletBinding()]
    param()
    Begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"
        $MutexName = "$($script:DeployQueueConfig.MutexPrefix)_ExecuteQueue"
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
        if (-not ($Mutex.WaitOne())) {
            Write-Error "Error acquiring Mutex (the system is already busy processing the queue)"
            return
        }
        try {
            $Item = Pop-DeployQueue -Unshift -ErrorAction Stop
            while ($Item) {
                Write-Verbose ("Running queue item #{0}: {1}" -f $Item.Name, $Item.Value)
                Invoke-Expression $Item.Value
                $Item = Pop-DeployQueue -Unshift -ErrorAction Stop
            }
        } catch {
            try {
                Send-DeployMail -Subject "Error in $($MyInvocation.MyCommand.Name)" -Body "<html><body><p>$($_.Exception | ConvertTo-Html)</p></body></html>"
            } catch {
                Write-Warning "Failed to send error notification: $_"
            }
            throw
        } finally {
            Write-Verbose "Mutex::Release"
            $Mutex.ReleaseMutex()
        }
    }
}
