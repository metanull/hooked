BeforeAll {
    $ModulePath = Join-Path $PSScriptRoot '..\..\src\MetaNull.PSStringToolkit\MetaNull.PSStringToolkit.psd1'
    Import-Module $ModulePath -Force
}

Describe 'ConvertTo-CamelCase' {
    It 'Converts space-separated to CamelCase' {
        'hello world' | ConvertTo-CamelCase | Should -Be 'HelloWorld'
    }
    It 'Removes non-word characters (except underscore)' {
        'hello-world_test' | ConvertTo-CamelCase | Should -Be 'HelloWorld_Test'
    }
    It 'Handles numbers' {
        'hello world 123' | ConvertTo-CamelCase | Should -Be 'HelloWorld123'
    }
}

Describe 'ConvertTo-CamelCaseKeys' {
    It 'Converts hashtable keys to CamelCase' {
        $result = @{'hello-world' = 42} | ConvertTo-CamelCaseKeys
        $result.Keys | Should -Contain 'HelloWorld'
        $result['HelloWorld'] | Should -Be 42
    }
    It 'Preserves values' {
        $result = @{'my key' = 'my value'} | ConvertTo-CamelCaseKeys
        $result.Values | Should -Contain 'my value'
    }
}

Describe 'ConvertTo-CamelCaseList' {
    It 'Converts string array to CamelCase' {
        $result = @('hello-world', 'foo bar') | ConvertTo-CamelCaseList
        $result | Should -Contain 'HelloWorld'
        $result | Should -Contain 'FooBar'
    }
}

Describe 'ConvertTo-Label' {
    It 'Converts to lowercase slug' {
        'SC.IIT.DIS.3' | ConvertTo-Label | Should -Be 'sc-iit-dis-3'
    }
    It 'Removes leading numbers' {
        '123hello' | ConvertTo-Label | Should -Be 'hello'
    }
    It 'Removes trailing dashes' {
        'hello---' | ConvertTo-Label | Should -Be 'hello'
    }
    It 'Converts with punctuation replacement' {
        'a.b@c&d|e' | ConvertTo-Label -ReplacePunctuation | Should -BeLike '*dot*at*and*or*'
    }
    It 'Starts with a letter' {
        '--42test' | ConvertTo-Label | Should -Be 'test'
    }
}

Describe 'ConvertTo-WellFormedXml' {
    It 'Parses simple HTML fragment' {
        $result = '<p>Hello</p>' | ConvertTo-WellFormedXml
        $result | Should -Not -BeNullOrEmpty
        $result.GetType().Name | Should -Be 'XDocument'
    }
    It 'Contains the original text' {
        $result = '<p>Test Content</p>' | ConvertTo-WellFormedXml
        $result.ToString() | Should -BeLike '*Test Content*'
    }
}

Describe 'ConvertTo-Serialized / ConvertFrom-Serialized' {
    It 'Roundtrips a hashtable' {
        $original = @{a = 1; b = 'two'}
        $xml = $original | ConvertTo-Serialized
        $xml | Should -BeLike '*<Obj*'
        $restored = $xml | ConvertFrom-Serialized
        $restored.a | Should -Be 1
        $restored.b | Should -Be 'two'
    }
    It 'Roundtrips an array' {
        $original = @(1, 2, 3)
        $xml = ConvertTo-Serialized -InputObject $original
        $restored = $xml | ConvertFrom-Serialized
        $restored.Count | Should -Be 3
    }
}

Describe 'Select-Join' {
    It 'Joins on matching property' {
        $left  = @([pscustomobject]@{Name = 'A'; Value = 1}, [pscustomobject]@{Name = 'B'; Value = 2})
        $right = @([pscustomobject]@{Name = 'A'; Score = 10}, [pscustomobject]@{Name = 'C'; Score = 30})
        $result = Select-Join $left $right Name
        $result.Count | Should -Be 1
        $result[0].LeftName | Should -Be 'A'
        $result[0].RightScore | Should -Be 10
    }
    It 'Returns empty for no matches' {
        $left  = @([pscustomobject]@{Name = 'A'})
        $right = @([pscustomobject]@{Name = 'B'})
        $result = Select-Join $left $right Name
        $result.Count | Should -Be 0
    }
}

Describe 'Test-IsExpired' {
    It 'Returns true when date is older than TTL' {
        $old = (Get-Date).AddMinutes(-10)
        Test-IsExpired -Date $old -Minutes 5 | Should -Be $true
    }
    It 'Returns false when date is within TTL' {
        $recent = (Get-Date).AddMinutes(-2)
        Test-IsExpired -Date $recent -Minutes 10 | Should -Be $false
    }
    It 'Accepts date string format' {
        $dateStr = (Get-Date).AddMinutes(-1).ToString('yyyyMMddHHmmss')
        Test-IsExpired -DateString $dateStr -Minutes 10 | Should -Be $false
    }
}

Describe 'ConvertTo-NullableJsonArray' {
    It 'Converts array to JSON' {
        $result = ConvertTo-NullableJsonArray -Object @('a', 'b')
        $result | Should -BeLike '*"a"*'
    }
    It 'Wraps single value in array' {
        $result = 'single' | ConvertTo-NullableJsonArray
        $result | Should -BeLike '*"single"*'
    }
    It 'Returns null for null input' {
        $result = $null | ConvertTo-NullableJsonArray
        $result | Should -BeNullOrEmpty
    }
}
