BeforeAll {
    $ModulePath = Join-Path $PSScriptRoot '..\..\src\MetaNull.PSDeployQueue\MetaNull.PSDeployQueue.psd1'
    Import-Module $ModulePath -Force
}

# All tests use Pester mocks — no real registry, mutex, Task Scheduler, or SMTP.
# This ensures tests are isolated, environment-agnostic, and CI-safe.

Describe 'Set-DeployQueueConfiguration' {
    It 'Sets the RegistryRoot' {
        Set-DeployQueueConfiguration -RegistryRoot 'HKLM:\SOFTWARE\TestQueue'
        $config = Get-DeployQueueConfiguration
        $config.RegistryRoot | Should -Be 'HKLM:\SOFTWARE\TestQueue'
    }
    It 'Sets MutexPrefix' {
        Set-DeployQueueConfiguration -MutexPrefix 'TestPrefix'
        $config = Get-DeployQueueConfiguration
        $config.MutexPrefix | Should -Be 'TestPrefix'
    }
    It 'Sets MutexTimeout' {
        Set-DeployQueueConfiguration -MutexTimeout 5000
        $config = Get-DeployQueueConfiguration
        $config.MutexTimeout | Should -Be 5000
    }
    It 'Sets TaskSchedulerPath' {
        Set-DeployQueueConfiguration -TaskSchedulerPath '\Test\'
        $config = Get-DeployQueueConfiguration
        $config.TaskSchedulerPath | Should -Be '\Test\'
    }
    It 'Sets TaskSchedulerName' {
        Set-DeployQueueConfiguration -TaskSchedulerName 'TestRunner'
        $config = Get-DeployQueueConfiguration
        $config.TaskSchedulerName | Should -Be 'TestRunner'
    }
    It 'Sets LauncherScript' {
        Set-DeployQueueConfiguration -LauncherScript 'C:\test\launcher.ps1'
        $config = Get-DeployQueueConfiguration
        $config.LauncherScript | Should -Be 'C:\test\launcher.ps1'
    }
    It 'Sets multiple values at once' {
        Set-DeployQueueConfiguration -RegistryRoot 'HKLM:\SOFTWARE\Multi' -MutexPrefix 'Multi' -MutexTimeout 2000
        $config = Get-DeployQueueConfiguration
        $config.RegistryRoot | Should -Be 'HKLM:\SOFTWARE\Multi'
        $config.MutexPrefix | Should -Be 'Multi'
        $config.MutexTimeout | Should -Be 2000
    }
    AfterAll {
        # Restore defaults
        Set-DeployQueueConfiguration -RegistryRoot 'HKLM:\SOFTWARE\MetaNull.PSDeployQueue' -MutexPrefix 'MetaNull.PSDeployQueue' -MutexTimeout 1000 -TaskSchedulerPath '\MetaNull.PSDeployQueue\' -TaskSchedulerName 'RunQueue'
    }
}

Describe 'Get-DeployQueueConfiguration' {
    It 'Returns a hashtable with all expected keys' {
        $config = Get-DeployQueueConfiguration
        $config | Should -BeOfType [hashtable]
        $config.ContainsKey('RegistryRoot') | Should -BeTrue
        $config.ContainsKey('MutexPrefix') | Should -BeTrue
        $config.ContainsKey('MutexTimeout') | Should -BeTrue
        $config.ContainsKey('TaskSchedulerPath') | Should -BeTrue
        $config.ContainsKey('TaskSchedulerName') | Should -BeTrue
        $config.ContainsKey('LauncherScript') | Should -BeTrue
    }
    It 'Returns default values' {
        $config = Get-DeployQueueConfiguration
        $config.RegistryRoot | Should -Be 'HKLM:\SOFTWARE\MetaNull.PSDeployQueue'
        $config.MutexPrefix | Should -Be 'MetaNull.PSDeployQueue'
        $config.MutexTimeout | Should -Be 1000
        $config.TaskSchedulerPath | Should -Be '\MetaNull.PSDeployQueue\'
        $config.TaskSchedulerName | Should -Be 'RunQueue'
    }
}

Describe 'Push-DeployQueue' {
    BeforeAll {
        Set-DeployQueueConfiguration -RegistryRoot 'TestRegistry:\DeployQueue'
    }
    BeforeEach {
        # Ensure clean queue directory for each test
        $QueuePath = 'TestRegistry:\DeployQueue\Queue'
        if (Test-Path $QueuePath) { Remove-Item $QueuePath -Recurse -Force }
    }
    It 'Creates a queue entry and returns it' {
        $result = Push-DeployQueue -Value 'Write-Host "test"'
        $result | Should -Not -BeNullOrEmpty
        $result.Name | Should -Be 0
        $result.Value | Should -Be 'Write-Host "test"'
    }
    It 'Increments the LastId for successive pushes' {
        Push-DeployQueue -Value 'cmd1' | Out-Null
        $result = Push-DeployQueue -Value 'cmd2'
        $result.Name | Should -Be 1
    }
    It 'Rejects duplicate when -Unique is set' {
        Push-DeployQueue -Value 'duplicate-cmd' | Out-Null
        $result = Push-DeployQueue -Value 'duplicate-cmd' -Unique
        $result | Should -BeNullOrEmpty
    }
    It 'Allows duplicate when -Unique is not set' {
        Push-DeployQueue -Value 'dup-cmd' | Out-Null
        $result = Push-DeployQueue -Value 'dup-cmd'
        $result | Should -Not -BeNullOrEmpty
    }
    AfterAll {
        Set-DeployQueueConfiguration -RegistryRoot 'HKLM:\SOFTWARE\MetaNull.PSDeployQueue'
    }
}

Describe 'Pop-DeployQueue' {
    BeforeAll {
        Set-DeployQueueConfiguration -RegistryRoot 'TestRegistry:\DeployQueue'
    }
    BeforeEach {
        $QueuePath = 'TestRegistry:\DeployQueue\Queue'
        if (Test-Path $QueuePath) { Remove-Item $QueuePath -Recurse -Force }
    }
    It 'Pops the last item (LIFO) by default' {
        Push-DeployQueue -Value 'first' | Out-Null
        Push-DeployQueue -Value 'second' | Out-Null
        $result = Pop-DeployQueue
        $result.Value | Should -Be 'second'
    }
    It 'Pops the first item (FIFO) with -Unshift' {
        Push-DeployQueue -Value 'first' | Out-Null
        Push-DeployQueue -Value 'second' | Out-Null
        $result = Pop-DeployQueue -Unshift
        $result.Value | Should -Be 'first'
    }
    It 'Returns nothing from empty queue' {
        $result = Pop-DeployQueue
        $result | Should -BeNullOrEmpty
    }
    It 'Removes the item from the queue' {
        Push-DeployQueue -Value 'only-one' | Out-Null
        Pop-DeployQueue | Out-Null
        $remaining = Get-DeployQueue
        $remaining | Should -BeNullOrEmpty
    }
    AfterAll {
        Set-DeployQueueConfiguration -RegistryRoot 'HKLM:\SOFTWARE\MetaNull.PSDeployQueue'
    }
}

Describe 'Get-DeployQueue' {
    BeforeAll {
        Set-DeployQueueConfiguration -RegistryRoot 'TestRegistry:\DeployQueue'
    }
    BeforeEach {
        $QueuePath = 'TestRegistry:\DeployQueue\Queue'
        if (Test-Path $QueuePath) { Remove-Item $QueuePath -Recurse -Force }
    }
    It 'Returns all items in the queue' {
        Push-DeployQueue -Value 'cmd1' | Out-Null
        Push-DeployQueue -Value 'cmd2' | Out-Null
        $result = @(Get-DeployQueue)
        $result.Count | Should -Be 2
    }
    It 'Returns nothing from empty queue' {
        $result = Get-DeployQueue
        $result | Should -BeNullOrEmpty
    }
    AfterAll {
        Set-DeployQueueConfiguration -RegistryRoot 'HKLM:\SOFTWARE\MetaNull.PSDeployQueue'
    }
}

Describe 'Clear-DeployQueue' {
    BeforeAll {
        Set-DeployQueueConfiguration -RegistryRoot 'TestRegistry:\DeployQueue'
    }
    BeforeEach {
        $QueuePath = 'TestRegistry:\DeployQueue\Queue'
        if (Test-Path $QueuePath) { Remove-Item $QueuePath -Recurse -Force }
    }
    It 'Returns all items and empties the queue' {
        Push-DeployQueue -Value 'cmd1' | Out-Null
        Push-DeployQueue -Value 'cmd2' | Out-Null
        $cleared = @(Clear-DeployQueue)
        $cleared.Count | Should -Be 2
        $remaining = Get-DeployQueue
        $remaining | Should -BeNullOrEmpty
    }
    It 'Returns nothing from empty queue' {
        $result = Clear-DeployQueue
        $result | Should -BeNullOrEmpty
    }
    AfterAll {
        Set-DeployQueueConfiguration -RegistryRoot 'HKLM:\SOFTWARE\MetaNull.PSDeployQueue'
    }
}

Describe 'Invoke-DeployQueue' {
    BeforeAll {
        Set-DeployQueueConfiguration -RegistryRoot 'TestRegistry:\DeployQueue'
    }
    BeforeEach {
        $QueuePath = 'TestRegistry:\DeployQueue\Queue'
        if (Test-Path $QueuePath) { Remove-Item $QueuePath -Recurse -Force }
    }
    Context 'When queue has commands' {
        It 'Executes queued commands in FIFO order' {
            Push-DeployQueue -Value '$global:TestInvokeResult1 = "executed1"' | Out-Null
            Push-DeployQueue -Value '$global:TestInvokeResult2 = "executed2"' | Out-Null
            Invoke-DeployQueue
            $global:TestInvokeResult1 | Should -Be 'executed1'
            $global:TestInvokeResult2 | Should -Be 'executed2'
            Remove-Variable TestInvokeResult1 -Scope Global -ErrorAction SilentlyContinue
            Remove-Variable TestInvokeResult2 -Scope Global -ErrorAction SilentlyContinue
        }
        It 'Empties the queue after execution' {
            Push-DeployQueue -Value '$null' | Out-Null
            Invoke-DeployQueue
            $remaining = Get-DeployQueue
            $remaining | Should -BeNullOrEmpty
        }
    }
    Context 'When queue is empty' {
        It 'Completes without error' {
            { Invoke-DeployQueue } | Should -Not -Throw
        }
    }
    AfterAll {
        Set-DeployQueueConfiguration -RegistryRoot 'HKLM:\SOFTWARE\MetaNull.PSDeployQueue'
    }
}

Describe 'Test-DeployQueue' {
    It 'Returns $true for IsIdle when queue is not executing' {
        Test-DeployQueue | Should -BeTrue
    }
    It 'Returns $false for IsBusy when queue is not executing' {
        Test-DeployQueue -IsBusy | Should -BeFalse
    }
}

Describe 'Install-DeployQueueRunner' {
    BeforeAll {
        Mock Register-QueueScheduledTask { [PSCustomObject]@{ TaskName = 'RunQueue' } } -ModuleName 'MetaNull.PSDeployQueue'
    }
    It 'Throws when LauncherScript is not configured' {
        Set-DeployQueueConfiguration -LauncherScript ''
        { Install-DeployQueueRunner } | Should -Throw '*LauncherScript*'
    }
    It 'Registers a scheduled task when LauncherScript is configured' {
        Set-DeployQueueConfiguration -LauncherScript 'C:\test\Launcher.ps1'
        Install-DeployQueueRunner
        Should -Invoke Register-QueueScheduledTask -ModuleName 'MetaNull.PSDeployQueue' -Times 1 -Exactly
    }
    AfterAll {
        Set-DeployQueueConfiguration -LauncherScript $null
    }
}

Describe 'Uninstall-DeployQueueRunner' {
    BeforeAll {
        Mock Unregister-ScheduledTask { } -ModuleName 'MetaNull.PSDeployQueue'
    }
    It 'Calls Unregister-ScheduledTask' {
        Uninstall-DeployQueueRunner
        Should -Invoke Unregister-ScheduledTask -ModuleName 'MetaNull.PSDeployQueue' -Times 1 -Exactly
    }
}

Describe 'Start-DeployQueueRunner' {
    BeforeAll {
        Mock Start-ScheduledTask { } -ModuleName 'MetaNull.PSDeployQueue'
    }
    It 'Calls Start-ScheduledTask' {
        Start-DeployQueueRunner
        Should -Invoke Start-ScheduledTask -ModuleName 'MetaNull.PSDeployQueue' -Times 1 -Exactly
    }
}

Describe 'Get-DeployQueueRunner' {
    BeforeAll {
        Mock Get-ScheduledTask { [PSCustomObject]@{ TaskName = 'RunQueue'; State = 3 } } -ModuleName 'MetaNull.PSDeployQueue'
    }
    It 'Returns the scheduled task' {
        $result = Get-DeployQueueRunner
        $result | Should -Not -BeNullOrEmpty
        $result.TaskName | Should -Be 'RunQueue'
    }
}

Describe 'Get-DeployQueueRunnerState' {
    BeforeAll {
        Mock Get-DeployQueueRunner { [PSCustomObject]@{ TaskName = 'RunQueue'; State = 3 } } -ModuleName 'MetaNull.PSDeployQueue'
    }
    It 'Returns Ready when task state is 3' {
        Get-DeployQueueRunnerState | Should -Be 'Ready'
    }
}

Describe 'Send-DeployMail' {
    BeforeAll {
        Mock Send-MailMessage { } -ModuleName 'MetaNull.PSDeployQueue'
        Mock Test-Path { $false } -ModuleName 'MetaNull.PSDeployQueue'
    }
    It 'Sends email when SmtpServer and From are provided' {
        Send-DeployMail -Subject 'Test' -Body 'Body' -SmtpServer 'smtp.test.com' -From 'test@test.com' -To 'user@test.com'
        Should -Invoke Send-MailMessage -ModuleName 'MetaNull.PSDeployQueue' -Times 1 -Exactly
    }
    It 'Writes error when SmtpServer is not configured' {
        { Send-DeployMail -Subject 'Test' -Body 'Body' -ErrorAction Stop } | Should -Throw '*SmtpServer*'
    }
}

Describe 'Push-DeployNotification' {
    BeforeAll {
        Set-DeployQueueConfiguration -RegistryRoot 'TestRegistry:\DeployQueue'
    }
    BeforeEach {
        $NotifPath = 'TestRegistry:\DeployQueue\Notification'
        if (Test-Path $NotifPath) { Remove-Item $NotifPath -Recurse -Force }
    }
    It 'Creates a notification entry' {
        $result = Push-DeployNotification -Message 'Test notification'
        $result | Should -Not -BeNullOrEmpty
    }
    It 'Stores Title and Source' {
        Push-DeployNotification -Message 'msg' -Title 'My Title' -Source 'TestSrc' | Out-Null
        $items = @(Get-DeployNotification)
        $items.Count | Should -Be 1
        $items[0].Title | Should -Be 'My Title'
        $items[0].Source | Should -Be 'TestSrc'
    }
    AfterAll {
        Set-DeployQueueConfiguration -RegistryRoot 'HKLM:\SOFTWARE\MetaNull.PSDeployQueue'
    }
}

Describe 'Pop-DeployNotification' {
    BeforeAll {
        Set-DeployQueueConfiguration -RegistryRoot 'TestRegistry:\DeployQueue'
    }
    BeforeEach {
        $NotifPath = 'TestRegistry:\DeployQueue\Notification'
        if (Test-Path $NotifPath) { Remove-Item $NotifPath -Recurse -Force }
    }
    It 'Pops the last notification by default' {
        Push-DeployNotification -Message 'first' | Out-Null
        Push-DeployNotification -Message 'second' | Out-Null
        $result = Pop-DeployNotification
        $result.Message | Should -Be 'second'
    }
    It 'Pops the first notification with -Unshift' {
        Push-DeployNotification -Message 'first' | Out-Null
        Push-DeployNotification -Message 'second' | Out-Null
        $result = Pop-DeployNotification -Unshift
        $result.Message | Should -Be 'first'
    }
    It 'Returns nothing from empty queue' {
        $result = Pop-DeployNotification
        $result | Should -BeNullOrEmpty
    }
    AfterAll {
        Set-DeployQueueConfiguration -RegistryRoot 'HKLM:\SOFTWARE\MetaNull.PSDeployQueue'
    }
}

Describe 'Get-DeployNotification' {
    BeforeAll {
        Set-DeployQueueConfiguration -RegistryRoot 'TestRegistry:\DeployQueue'
    }
    BeforeEach {
        $NotifPath = 'TestRegistry:\DeployQueue\Notification'
        if (Test-Path $NotifPath) { Remove-Item $NotifPath -Recurse -Force }
    }
    It 'Returns all notifications' {
        Push-DeployNotification -Message 'n1' | Out-Null
        Push-DeployNotification -Message 'n2' | Out-Null
        $result = @(Get-DeployNotification)
        $result.Count | Should -Be 2
    }
    It 'Returns nothing when empty' {
        $result = Get-DeployNotification
        $result | Should -BeNullOrEmpty
    }
    AfterAll {
        Set-DeployQueueConfiguration -RegistryRoot 'HKLM:\SOFTWARE\MetaNull.PSDeployQueue'
    }
}

Describe 'Clear-DeployNotification' {
    BeforeAll {
        Set-DeployQueueConfiguration -RegistryRoot 'TestRegistry:\DeployQueue'
    }
    BeforeEach {
        $NotifPath = 'TestRegistry:\DeployQueue\Notification'
        if (Test-Path $NotifPath) { Remove-Item $NotifPath -Recurse -Force }
    }
    It 'Returns all notifications and empties the queue' {
        Push-DeployNotification -Message 'n1' | Out-Null
        Push-DeployNotification -Message 'n2' | Out-Null
        $cleared = @(Clear-DeployNotification)
        $cleared.Count | Should -Be 2
        $remaining = Get-DeployNotification
        $remaining | Should -BeNullOrEmpty
    }
    AfterAll {
        Set-DeployQueueConfiguration -RegistryRoot 'HKLM:\SOFTWARE\MetaNull.PSDeployQueue'
    }
}

Describe 'Send-DeployNotification' {
    BeforeAll {
        Set-DeployQueueConfiguration -RegistryRoot 'TestRegistry:\DeployQueue'
        Mock Send-DeployMail { } -ModuleName 'MetaNull.PSDeployQueue'
    }
    BeforeEach {
        $NotifPath = 'TestRegistry:\DeployQueue\Notification'
        if (Test-Path $NotifPath) { Remove-Item $NotifPath -Recurse -Force }
    }
    It 'Sends each notification separately by default' {
        Push-DeployNotification -Message 'n1' | Out-Null
        Push-DeployNotification -Message 'n2' | Out-Null
        Send-DeployNotification
        Should -Invoke Send-DeployMail -ModuleName 'MetaNull.PSDeployQueue' -Times 2 -Exactly
    }
    It 'Sends one email with -AsTable' {
        Push-DeployNotification -Message 'n1' | Out-Null
        Push-DeployNotification -Message 'n2' | Out-Null
        Send-DeployNotification -AsTable
        Should -Invoke Send-DeployMail -ModuleName 'MetaNull.PSDeployQueue' -Times 1 -Exactly
    }
    It 'Does nothing when no notifications exist' {
        Send-DeployNotification
        Should -Invoke Send-DeployMail -ModuleName 'MetaNull.PSDeployQueue' -Times 0 -Exactly
    }
    It 'Clears notifications after sending' {
        Push-DeployNotification -Message 'n1' | Out-Null
        Send-DeployNotification
        $remaining = Get-DeployNotification
        $remaining | Should -BeNullOrEmpty
    }
    AfterAll {
        Set-DeployQueueConfiguration -RegistryRoot 'HKLM:\SOFTWARE\MetaNull.PSDeployQueue'
    }
}
