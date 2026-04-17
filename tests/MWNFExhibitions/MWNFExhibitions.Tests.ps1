Describe 'MWNFExhibitions' {
    BeforeAll {
        $localMetaNullRoot = Join-Path $PSScriptRoot '..\..\src'
        if (Test-Path $localMetaNullRoot) {
            $metaNullRoot = Resolve-Path $localMetaNullRoot
            $env:PSModulePath = (($metaNullRoot.Path, $env:PSModulePath) -join ';')
        }

        $modulePath = Join-Path $PSScriptRoot '..\..\src\MWNFExhibitions\MWNFExhibitions.psd1'
        Import-Module $modulePath -Force

        InModuleScope MWNFExhibitions {
            $script:MWNFExhibitionsConfig.RegistryHive = 'TestRegistry:\SOFTWARE\MWNFExhibitions'
            $script:MWNFExhibitionsConfig.TemplateFile = Join-Path $TestDrive 'unused.reg'
        }
    }

    BeforeEach {
        $root = 'TestRegistry:\SOFTWARE\MWNFExhibitions\ExhibitionServer'
        if (Test-Path $root) {
            Remove-Item -Path $root -Recurse -Force
        }

        New-Item -Path $root -ItemType Directory -Force | Out-Null
        New-Item -Path (Join-Path $root 'Settings') -ItemType Directory -Force | Out-Null
        New-Item -Path (Join-Path $root 'Settings\ApiEnvironment') -ItemType Directory -Force | Out-Null
        New-Item -Path (Join-Path $root 'Settings\ClientEnvironment') -ItemType Directory -Force | Out-Null
        New-Item -Path (Join-Path $root 'Exhibitions') -ItemType Directory -Force | Out-Null
        New-Item -Path 'TestRegistry:\SOFTWARE\MWNFExhibitions\Settings' -ItemType Directory -Force | Out-Null

        Set-ItemProperty -Path (Join-Path $root 'Settings') -Name 'Directory' -Value 'C:\deploy\{Name}\{LanguageId}'
        Set-ItemProperty -Path (Join-Path $root 'Settings') -Name 'DirectoryLeafTemporary' -Value 'tmp'
        Set-ItemProperty -Path (Join-Path $root 'Settings') -Name 'ApiRepository' -Value 'https://example.invalid/api.git'
        Set-ItemProperty -Path (Join-Path $root 'Settings') -Name 'ClientRepository' -Value 'https://example.invalid/client.git'
        Set-ItemProperty -Path (Join-Path $root 'Settings') -Name 'ApiBranch' -Value 'master'
        Set-ItemProperty -Path (Join-Path $root 'Settings') -Name 'ClientBranch' -Value 'master'
        Set-ItemProperty -Path (Join-Path $root 'Settings') -Name 'TargetDirectoryApi' -Value 'C:\inetpub\api\{Name}\{LanguageId}'
        Set-ItemProperty -Path (Join-Path $root 'Settings') -Name 'TargetDirectoryClient' -Value 'C:\inetpub\client\{Name}\{LanguageId}'
        Set-ItemProperty -Path (Join-Path $root 'Settings') -Name 'ClientBaseUri' -Value 'https://example.invalid/{Name}/{LanguageId}'
        Set-ItemProperty -Path (Join-Path $root 'Settings\ApiEnvironment') -Name 'APP_NAME' -Value '{Name}'
        Set-ItemProperty -Path (Join-Path $root 'Settings\ClientEnvironment') -Name 'VITE_APP_NAME' -Value '{Name}'
    }

Describe 'Validation helpers' {
    It 'Accepts a valid exhibition name' {
        Test-ExhibitionName -Name 'the_use_of_colours_in_art' | Should -BeTrue
    }

    It 'Rejects an invalid exhibition name' {
        Test-ExhibitionName -Name 'BadName' | Should -BeFalse
    }

    It 'Accepts a valid language id' {
        Test-LanguageId -LanguageId 'en' | Should -BeTrue
    }

    It 'Rejects an invalid language id' {
        Test-LanguageId -LanguageId 'eng' | Should -BeFalse
    }
}

Describe 'Import-ExhibitionServerConfiguration' {
    It 'Returns the configured registry structure' {
        $result = Import-ExhibitionServerConfiguration
        $result.Path | Should -Be 'TestRegistry:\SOFTWARE\MWNFExhibitions\ExhibitionServer'
        $result.Settings.Directory | Should -Be 'C:\deploy\{Name}\{LanguageId}'
        $result.ApiEnvironment.APP_NAME | Should -Be '{Name}'
    }
}

Describe 'Install-Exhibition and Get-Exhibition' {
    It 'Installs an exhibition and returns it' {
        $result = Install-Exhibition -Name 'the_use_of_colours_in_art' -LanguageId 'en' -ApiEnvironment @('APP_NAME="Colours"', 'DB_HOST="ignored"') -ClientEnvironment @('VITE_APP_NAME="Colours"', 'VUE_APP_URL_SELF="ignored"')
        $result.Name | Should -Be 'the_use_of_colours_in_art'
        $result.LanguageId | Should -Be 'en'
    }

    It 'Stores only non-forced environment values' {
        Install-Exhibition -Name 'arts_in_dialogue' -LanguageId 'de' -ApiEnvironment @('APP_NAME="Dialogue"', 'DB_HOST="ignored"') -ClientEnvironment @('VITE_APP_NAME="Dialogue"', 'VUE_APP_URL_SELF="ignored"') | Out-Null
        $result = Get-Exhibition -Name 'arts_in_dialogue' -LanguageId 'de'
        $result.ApiEnvironment.APP_NAME | Should -Be 'Dialogue'
        $result.ApiEnvironment.PSObject.Properties.Name | Should -Not -Contain 'DB_HOST'
        $result.ClientEnvironment.PSObject.Properties.Name | Should -Not -Contain 'VUE_APP_URL_SELF'
    }

    It 'Returns summary rows when no filter is provided' {
        Install-Exhibition -Name 'arts_in_dialogue' -LanguageId 'de' -ApiEnvironment @('APP_NAME="Dialogue"') -ClientEnvironment @('VITE_APP_NAME="Dialogue"') | Out-Null
        $result = @(Get-Exhibition)
        $result.Count | Should -Be 1
        $result[0].Name | Should -Be 'arts_in_dialogue'
        $result[0].LanguageId | Should -Be 'de'
    }
}

Describe 'Uninstall-Exhibition' {
    It 'Removes an installed exhibition' {
        Install-Exhibition -Name 'arts_in_dialogue' -LanguageId 'de' -ApiEnvironment @('APP_NAME="Dialogue"') -ClientEnvironment @('VITE_APP_NAME="Dialogue"') | Out-Null
        Uninstall-Exhibition -Name 'arts_in_dialogue' -LanguageId 'de' | Out-Null
        { Get-Exhibition -Name 'arts_in_dialogue' -LanguageId 'de' } | Should -Not -Throw
        @(Get-Exhibition -Name 'arts_in_dialogue' -LanguageId 'de').Count | Should -Be 0
    }
}

Describe 'Set-ExhibitionServerDatabaseCredential' {
    It 'Stores encrypted credentials on the settings key' {
        $password = ConvertTo-SecureString 'TestPass123!' -AsPlainText -Force
        $credential = New-Object pscredential('db-user', $password)

        Set-ExhibitionServerDatabaseCredential -Credential $credential -DatabaseName 'mwnf3'

        $settings = Get-ItemProperty -Path 'TestRegistry:\SOFTWARE\MWNFExhibitions\ExhibitionServer\Settings'
        $settings.DatabaseUsername | Should -Be 'db-user'
        $settings.DatabaseName | Should -Be 'mwnf3'
        $settings.DatabasePassword | Should -Not -BeNullOrEmpty
        Unprotect-String -InputString $settings.DatabasePassword | Should -Be 'TestPass123!'
    }
}
}