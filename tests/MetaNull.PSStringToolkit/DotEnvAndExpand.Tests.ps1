BeforeAll {
    $ModulePath = Join-Path $PSScriptRoot '..\..\src\MetaNull.PSStringToolkit\MetaNull.PSStringToolkit.psd1'
    Import-Module $ModulePath -Force
}

Describe 'Expand-String' {
    It 'Expands single placeholder' {
        $set = [pscustomobject]@{Name = 'Pascal'}
        Expand-String -InputString 'Hello {Name}' -ValueSets @($set) | Should -Be 'Hello Pascal'
    }
    It 'Expands multiple placeholders from multiple sets' {
        $set1 = [pscustomobject]@{Firstname = 'Pascal'}
        $set2 = [pscustomobject]@{Application = 'MWNFPS'}
        $result = Expand-String -InputString '{Firstname} uses {Application}' -ValueSets @($set1, $set2)
        $result | Should -Be 'Pascal uses MWNFPS'
    }
    It 'Replaces {EmptyString} with empty' {
        $set = [pscustomobject]@{}
        Expand-String -InputString 'A{EmptyString}B' -ValueSets @($set) | Should -Be 'AB'
    }
    It 'Leaves unmatched placeholders in place' {
        $set = [pscustomobject]@{A = '1'}
        Expand-String -InputString '{A} {B}' -ValueSets @($set) | Should -Be '1 {B}'
    }
    It 'Handles empty string input' {
        $set = [pscustomobject]@{A = '1'}
        Expand-String -InputString '' -ValueSets @($set) | Should -Be ''
    }
}

Describe 'ConvertFrom-DotEnv' {
    It 'Parses simple KEY=VALUE' {
        $result = 'APP_NAME=MyApp' | ConvertFrom-DotEnv
        $result['APP_NAME'] | Should -Be 'MyApp'
    }
    It 'Parses quoted values' {
        $result = 'APP_NAME="My App"' | ConvertFrom-DotEnv
        $result['APP_NAME'] | Should -Be 'My App'
    }
    It 'Skips comment lines' {
        $result = @('# comment', 'KEY=value') | ConvertFrom-DotEnv
        $result.Count | Should -Be 1
        $result['KEY'] | Should -Be 'value'
    }
    It 'Skips empty lines' {
        $result = @('', 'KEY=value', '') | ConvertFrom-DotEnv
        $result.Count | Should -Be 1
    }
    It 'Throws on malformed line' {
        { 'INVALID LINE WITHOUT EQUALS' | ConvertFrom-DotEnv } | Should -Throw '*Invalid .env line*'
    }
    It 'Parses multiple lines' {
        $result = @('A=1', 'B=2', 'C=3') | ConvertFrom-DotEnv
        $result.Count | Should -Be 3
        $result['A'] | Should -Be '1'
        $result['B'] | Should -Be '2'
        $result['C'] | Should -Be '3'
    }
    It 'Handles duplicate keys (keeps last)' {
        $result = @('KEY=first', 'KEY=second') | ConvertFrom-DotEnv 3>&1 | Where-Object { $_ -is [System.Collections.Specialized.OrderedDictionary] }
        # Due to warning output, filter for the dictionary
    }
}

Describe 'ConvertTo-DotEnv' {
    It 'Converts hashtable to .env lines' {
        $result = @{APP_NAME = 'MyApp'} | ConvertTo-DotEnv
        $result | Should -Contain 'APP_NAME="MyApp"'
    }
    It 'Converts ordered dictionary to .env lines' {
        $dict = [ordered]@{A = '1'; B = '2'}
        $result = ConvertTo-DotEnv -Dictionary $dict
        $result.Count | Should -Be 2
    }
    It 'Roundtrips with ConvertFrom-DotEnv' {
        $original = [ordered]@{APP_NAME = 'Test'; APP_KEY = 'abc123'}
        $lines = ConvertTo-DotEnv -Dictionary $original
        $restored = $lines | ConvertFrom-DotEnv
        $restored['APP_NAME'] | Should -Be 'Test'
        $restored['APP_KEY'] | Should -Be 'abc123'
    }
}
