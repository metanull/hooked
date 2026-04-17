function Test-DeployQueue {
    <#
        .SYNOPSIS
            Test the state of the deploy queue.
        .DESCRIPTION
            By default (or with -IsIdle), returns $true when the queue is idle (ready for execution).
            With -IsBusy, returns $true when the queue is currently executing.
        .PARAMETER IsIdle
            If defined, or if no parameters are passed, tests if the queue is idle.
        .PARAMETER IsBusy
            If defined, tests if the queue is busy executing.
    #>
    [CmdletBinding(DefaultParameterSetName = 'IsIdle')]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $false, ParameterSetName = 'IsIdle')]
        [switch]$IsIdle,

        [Parameter(Mandatory = $true, ParameterSetName = 'IsBusy')]
        [switch]$IsBusy
    )
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
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"
        try {
            Write-Verbose "Mutex::Wait (0ms timeout)"
            $CanExecute = $Mutex.WaitOne(0)
            return ($CanExecute -xor $IsBusy)
        } finally {
            if ($CanExecute) {
                Write-Verbose "Mutex::Release"
                $Mutex.ReleaseMutex()
            }
        }
    }
}
