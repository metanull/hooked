BeforeAll {
    # Load dependency first (PSStringToolkit provides ConvertTo-Hash, Test-IsExpired)
    $DependencyPath = Join-Path $PSScriptRoot '..\..\src\MetaNull.PSStringToolkit\MetaNull.PSStringToolkit.psd1'
    Import-Module $DependencyPath -Force
    $ModulePath = Join-Path $PSScriptRoot '..\..\src\MetaNull.PSCredentialCache\MetaNull.PSCredentialCache.psd1'
    Import-Module $ModulePath -Force
}

# All tests use Pester mocks — no real registry, DPAPI, or credential prompts.
# This ensures tests are isolated, environment-agnostic, and CI-safe.

Describe 'Set-CredentialCacheConfiguration' {
    It 'Sets the RegistryRoot' {
        Set-CredentialCacheConfiguration -RegistryRoot 'HKCU:\SOFTWARE\TestRoot'
        $config = Get-CredentialCacheConfiguration
        $config.RegistryRoot | Should -Be 'HKCU:\SOFTWARE\TestRoot'
    }
    It 'Sets the CacheDurationMinutes' {
        Set-CredentialCacheConfiguration -CacheDurationMinutes 60
        $config = Get-CredentialCacheConfiguration
        $config.CacheDurationMinutes | Should -Be 60
    }
    It 'Sets both values at once' {
        Set-CredentialCacheConfiguration -RegistryRoot 'HKCU:\SOFTWARE\Both' -CacheDurationMinutes 120
        $config = Get-CredentialCacheConfiguration
        $config.RegistryRoot | Should -Be 'HKCU:\SOFTWARE\Both'
        $config.CacheDurationMinutes | Should -Be 120
    }
    AfterAll {
        # Restore defaults
        Set-CredentialCacheConfiguration -RegistryRoot 'HKCU:\SOFTWARE\MetaNull.PSCredentialCache' -CacheDurationMinutes 43200
    }
}

Describe 'Get-CredentialCacheConfiguration' {
    It 'Returns a hashtable with RegistryRoot and CacheDurationMinutes' {
        $config = Get-CredentialCacheConfiguration
        $config | Should -BeOfType [hashtable]
        $config.ContainsKey('RegistryRoot') | Should -BeTrue
        $config.ContainsKey('CacheDurationMinutes') | Should -BeTrue
    }
    It 'Returns default values after module load' {
        $config = Get-CredentialCacheConfiguration
        $config.RegistryRoot | Should -Be 'HKCU:\SOFTWARE\MetaNull.PSCredentialCache'
        $config.CacheDurationMinutes | Should -Be 43200
    }
}

Describe 'Protect-String' {
    It 'Returns a non-empty encrypted string' {
        $result = Protect-String -InputString 'hello world'
        $result | Should -Not -BeNullOrEmpty
        $result | Should -BeOfType [string]
    }
    It 'Returns a different string than the input' {
        $result = Protect-String -InputString 'secret'
        $result | Should -Not -Be 'secret'
    }
    It 'Accepts pipeline input' {
        $result = 'pipeline test' | Protect-String
        $result | Should -Not -BeNullOrEmpty
    }
}

Describe 'Unprotect-String' {
    Context 'String parameter set' {
        It 'Decrypts a DPAPI-encrypted string back to plain text' {
            $original = 'round trip test'
            $encrypted = Protect-String -InputString $original
            $decrypted = Unprotect-String -InputString $encrypted
            $decrypted | Should -Be $original
        }
        It 'Handles special characters' {
            $original = 'p@$$w0rd!#%^&*()_+-=[]{}|;:,.<>?'
            $encrypted = Protect-String -InputString $original
            $decrypted = Unprotect-String -InputString $encrypted
            $decrypted | Should -Be $original
        }
        It 'Handles unicode characters' {
            $original = 'Ünïcödë Pässwörd 日本語'
            $encrypted = Protect-String -InputString $original
            $decrypted = Unprotect-String -InputString $encrypted
            $decrypted | Should -Be $original
        }
    }
    Context 'SecureString parameter set' {
        It 'Decrypts a SecureString to plain text' {
            $original = 'secure string test'
            $secure = ConvertTo-SecureString -String $original -AsPlainText -Force
            $decrypted = Unprotect-String -InputSecureString $secure
            $decrypted | Should -Be $original
        }
    }
}

Describe 'New-CachedCredential' {
    BeforeAll {
        $TestRegistryRoot = 'TestDrive:\CredentialCache'
    }
    Context 'With credential_provided parameter set' {
        BeforeAll {
            Mock New-Item { } -ModuleName 'MetaNull.PSCredentialCache'
            Mock New-ItemProperty { } -ModuleName 'MetaNull.PSCredentialCache'
        }
        It 'Stores a credential and returns it' {
            $secPass = ConvertTo-SecureString 'TestPass123' -AsPlainText -Force
            $cred = New-Object pscredential('testuser@domain.com', $secPass)
            $result = New-CachedCredential -Credential $cred -RegistryRoot $TestRegistryRoot
            $result | Should -Not -BeNullOrEmpty
            $result.UserName | Should -Be 'testuser@domain.com'
        }
        It 'Calls New-Item to create registry key' {
            $secPass = ConvertTo-SecureString 'TestPass123' -AsPlainText -Force
            $cred = New-Object pscredential('testuser@domain.com', $secPass)
            New-CachedCredential -Credential $cred -RegistryRoot $TestRegistryRoot | Out-Null
            Should -Invoke New-Item -ModuleName 'MetaNull.PSCredentialCache' -Times 1 -Exactly
        }
        It 'Calls New-ItemProperty for each stored property' {
            $secPass = ConvertTo-SecureString 'TestPass123' -AsPlainText -Force
            $cred = New-Object pscredential('testuser@domain.com', $secPass)
            New-CachedCredential -Credential $cred -RegistryRoot $TestRegistryRoot | Out-Null
            # UserName, Password, Domain, DomainUserName, LastUpdate = 5 properties
            Should -Invoke New-ItemProperty -ModuleName 'MetaNull.PSCredentialCache' -Times 5 -Exactly
        }
        It 'Throws on empty credential' {
            { New-CachedCredential -Credential ([System.Management.Automation.PSCredential]::Empty) -RegistryRoot $TestRegistryRoot } | Should -Throw
        }
    }
}

Describe 'Get-CachedCredential' {
    BeforeAll {
        $TestRegistryRoot = 'TestDrive:\CredentialCache'
        $TestPassword = 'MySecretPassword'
        $TestUser = 'cached@example.com'
        $EncryptedPass = ConvertTo-SecureString $TestPassword -AsPlainText -Force | ConvertFrom-SecureString
        $FreshDate = Get-Date -Format 'yyyyMMddHHmmss'
    }
    Context 'When credential exists and is not expired' {
        BeforeAll {
            Mock Get-ItemProperty {
                [PSCustomObject]@{
                    UserName   = $TestUser
                    Password   = $EncryptedPass
                    LastUpdate = $FreshDate
                }
            } -ModuleName 'MetaNull.PSCredentialCache'
            Mock Set-ItemProperty { } -ModuleName 'MetaNull.PSCredentialCache'
            Mock Test-IsExpired { $false } -ModuleName 'MetaNull.PSCredentialCache'
        }
        It 'Returns a PSCredential' {
            $result = Get-CachedCredential -UserName $TestUser -RegistryRoot $TestRegistryRoot
            $result | Should -Not -BeNullOrEmpty
            $result.UserName | Should -Be $TestUser
        }
        It 'Updates the LastUpdate timestamp' {
            Get-CachedCredential -UserName $TestUser -RegistryRoot $TestRegistryRoot | Out-Null
            Should -Invoke Set-ItemProperty -ModuleName 'MetaNull.PSCredentialCache' -Times 1 -Exactly
        }
    }
    Context 'When credential is expired' {
        BeforeAll {
            Mock Get-ItemProperty {
                [PSCustomObject]@{
                    UserName   = $TestUser
                    Password   = $EncryptedPass
                    LastUpdate = '20200101000000'
                }
            } -ModuleName 'MetaNull.PSCredentialCache'
            Mock Test-IsExpired { $true } -ModuleName 'MetaNull.PSCredentialCache'
        }
        It 'Writes an error for expired credentials' {
            $result = Get-CachedCredential -UserName $TestUser -RegistryRoot $TestRegistryRoot -ErrorAction SilentlyContinue -ErrorVariable err
            $err.Count | Should -BeGreaterThan 0
        }
    }
    Context 'With -NoExpiration switch' {
        BeforeAll {
            Mock Get-ItemProperty {
                [PSCustomObject]@{
                    UserName   = $TestUser
                    Password   = $EncryptedPass
                    LastUpdate = '20200101000000'
                }
            } -ModuleName 'MetaNull.PSCredentialCache'
        }
        It 'Returns the credential regardless of age' {
            $result = Get-CachedCredential -UserName $TestUser -RegistryRoot $TestRegistryRoot -NoExpiration
            $result | Should -Not -BeNullOrEmpty
            $result.UserName | Should -Be $TestUser
        }
    }
    Context 'When credential does not exist' {
        BeforeAll {
            Mock Get-ItemProperty { throw "Cannot find path" } -ModuleName 'MetaNull.PSCredentialCache'
        }
        It 'Throws when registry key is missing' {
            { Get-CachedCredential -UserName 'nonexistent@example.com' -RegistryRoot $TestRegistryRoot } | Should -Throw
        }
    }
}

Describe 'Test-CachedCredential' {
    BeforeAll {
        $TestRegistryRoot = 'TestDrive:\CredentialCache'
        $FreshDate = Get-Date -Format 'yyyyMMddHHmmss'
    }
    Context 'When credential exists and is not expired' {
        BeforeAll {
            Mock Get-ItemProperty {
                [PSCustomObject]@{ LastUpdate = $FreshDate }
            } -ModuleName 'MetaNull.PSCredentialCache'
            Mock Test-IsExpired { $false } -ModuleName 'MetaNull.PSCredentialCache'
        }
        It 'Returns $true' {
            Test-CachedCredential -UserName 'user@example.com' -RegistryRoot $TestRegistryRoot | Should -BeTrue
        }
    }
    Context 'When credential is expired' {
        BeforeAll {
            Mock Get-ItemProperty {
                [PSCustomObject]@{ LastUpdate = '20200101000000' }
            } -ModuleName 'MetaNull.PSCredentialCache'
            Mock Test-IsExpired { $true } -ModuleName 'MetaNull.PSCredentialCache'
        }
        It 'Returns $false' {
            Test-CachedCredential -UserName 'user@example.com' -RegistryRoot $TestRegistryRoot | Should -BeFalse
        }
    }
    Context 'When credential does not exist' {
        BeforeAll {
            Mock Get-ItemProperty { $null } -ModuleName 'MetaNull.PSCredentialCache'
        }
        It 'Returns $false' {
            Test-CachedCredential -UserName 'missing@example.com' -RegistryRoot $TestRegistryRoot | Should -BeFalse
        }
    }
    Context 'With -NoExpiration switch' {
        BeforeAll {
            Mock Get-ItemProperty {
                [PSCustomObject]@{ LastUpdate = '20200101000000' }
            } -ModuleName 'MetaNull.PSCredentialCache'
        }
        It 'Returns $true regardless of age' {
            Test-CachedCredential -UserName 'user@example.com' -RegistryRoot $TestRegistryRoot -NoExpiration | Should -BeTrue
        }
    }
    Context 'With -NoExpiration but no credential' {
        BeforeAll {
            Mock Get-ItemProperty { $null } -ModuleName 'MetaNull.PSCredentialCache'
        }
        It 'Returns $false when credential does not exist' {
            Test-CachedCredential -UserName 'missing@example.com' -RegistryRoot $TestRegistryRoot -NoExpiration | Should -BeFalse
        }
    }
}

Describe 'Remove-CachedCredential' {
    BeforeAll {
        $TestRegistryRoot = 'TestDrive:\CredentialCache'
        Mock Remove-Item { } -ModuleName 'MetaNull.PSCredentialCache'
    }
    It 'Calls Remove-Item with the correct registry path' {
        Remove-CachedCredential -UserName 'user@example.com' -RegistryRoot $TestRegistryRoot
        Should -Invoke Remove-Item -ModuleName 'MetaNull.PSCredentialCache' -Times 1 -Exactly
    }
    It 'Uses the configured registry root when none specified' {
        Set-CredentialCacheConfiguration -RegistryRoot 'HKCU:\SOFTWARE\TestConfig'
        Remove-CachedCredential -UserName 'user@example.com'
        Should -Invoke Remove-Item -ModuleName 'MetaNull.PSCredentialCache' -Times 1
        Set-CredentialCacheConfiguration -RegistryRoot 'HKCU:\SOFTWARE\MetaNull.PSCredentialCache'
    }
}
