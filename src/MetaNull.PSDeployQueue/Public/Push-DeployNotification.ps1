function Push-DeployNotification {
    <#
        .SYNOPSIS
            Queue a notification message for later sending by email.
        .DESCRIPTION
            Adds a notification to the registry-backed notification queue. Protected by a mutex.
        .PARAMETER Message
            The notification message body.
        .PARAMETER Title
            An optional title for the notification.
        .PARAMETER Source
            An optional source identifier for the notification.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
        [string]$Message,

        [Parameter(Position = 1, Mandatory = $false)]
        [AllowEmptyString()]
        [AllowNull()]
        [string]$Title = $null,

        [Parameter(Position = 2, Mandatory = $false)]
        [AllowEmptyString()]
        [AllowNull()]
        [string]$Source = $null
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
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"
        Write-Verbose "Mutex::Wait"
        if (-not ($Mutex.WaitOne($script:DeployQueueConfig.MutexTimeout))) {
            Write-Error "Error acquiring Mutex (the system is busy with another operation)"
            return
        }
        try {
            $RegistryKey = Join-Path $script:DeployQueueConfig.RegistryRoot 'Notification'
            if (-not (Test-Path $RegistryKey)) {
                New-Item $RegistryKey -Force -ErrorAction Stop | Out-Null
            }
            $Notification = Get-Item $RegistryKey -ErrorAction Stop
            $LastId = 0
            try {
                $LastId = $Notification | Get-ItemPropertyValue -Name LastId -ErrorAction Stop
                $LastId = ([int]$LastId) + 1
            } catch {
                $LastId = 0
            }
            Write-Verbose "LastId: $LastId"

            $Notification | Set-ItemProperty -Name LastId -Value ([int]$LastId) -ErrorAction Stop
            $NewItem = New-Item -Path (Join-Path -Path $RegistryKey -ChildPath ([string]$LastId))
            $NewItem | Set-ItemProperty -Name Date -Value (Get-Date -Format o)
            $NewItem | Set-ItemProperty -Name Title -Value $Title
            $NewItem | Set-ItemProperty -Name Source -Value $Source
            $NewItem | Set-ItemProperty -Name Message -Value $Message
            return $NewItem
        } finally {
            Write-Verbose "Mutex::Release"
            $Mutex.ReleaseMutex()
        }
    }
}
