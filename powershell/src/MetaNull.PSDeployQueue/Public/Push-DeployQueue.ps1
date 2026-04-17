function Push-DeployQueue {
    <#
        .SYNOPSIS
            Enqueue a command for later execution.
        .DESCRIPTION
            Adds a command string to the registry-backed queue. Queue operations are
            protected by a mutex to avoid race conditions on concurrent processes.
        .PARAMETER Value
            The PowerShell command to queue.
        .PARAMETER Unique
            If set, and an identical command is already queued, the operation is not pushed.
        .PARAMETER StartQueue
            If set, the queue runner is triggered immediately after pushing the command.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
        [string]$Value,

        [Parameter(Mandatory = $false)]
        [switch]$Unique,

        [Parameter(Mandatory = $false)]
        [switch]$StartQueue
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
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"
        Write-Verbose "Mutex::Wait"
        if (-not ($Mutex.WaitOne($script:DeployQueueConfig.MutexTimeout))) {
            Write-Error "Error acquiring Mutex (the system is busy with another operation)"
            return
        }
        try {
            $RegistryKey = Join-Path $script:DeployQueueConfig.RegistryRoot 'Queue'
            if (-not (Test-Path $RegistryKey)) {
                New-Item $RegistryKey -Force -ErrorAction Stop | Out-Null
            }
            $Queue = Get-Item $RegistryKey -ErrorAction Stop
            $LastId = 0
            try {
                $LastId = $Queue | Get-ItemPropertyValue -Name LastId -ErrorAction Stop
                $LastId = ([int]$LastId) + 1
            } catch {
                $LastId = 0
            }
            Write-Verbose "LastId: $LastId"

            $DoStoreItem = $true
            if ($Unique) {
                $Items = $Queue | Get-ItemProperty
                if ($Items.PSObject.Properties | Where-Object { $_.Name -match '^\d+$' -and $Items.($_.Name) -eq $Value }) {
                    $DoStoreItem = $false
                }
            }
            if ($DoStoreItem) {
                $NewItem = [PSCustomObject]@{ Name = [int]$LastId; Value = $Value }
                $Queue | Set-ItemProperty -Name $NewItem.Name -Value $NewItem.Value -ErrorAction Stop
                $Queue | Set-ItemProperty -Name LastId -Value ([int]$LastId) -ErrorAction Stop
                return $NewItem
            }
        } finally {
            Write-Verbose "Mutex::Release"
            $Mutex.ReleaseMutex()

            if ($StartQueue) {
                Start-DeployQueueRunner
            }
        }
    }
}
