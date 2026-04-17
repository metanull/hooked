BeforeAll {
    $ModulePath = Join-Path $PSScriptRoot '..\..\src\MetaNull.PSStringToolkit\MetaNull.PSStringToolkit.psd1'
    Import-Module $ModulePath -Force
}

Describe 'ConvertTo-UrlEncoded' {
    It 'Encodes spaces as plus' {
        ConvertTo-UrlEncoded 'hello world' | Should -Be 'hello+world'
    }
    It 'Encodes special characters' {
        ConvertTo-UrlEncoded 'a=b&c=d' | Should -Be 'a%3db%26c%3dd'
    }
    It 'Passes simple alphanumeric through' {
        ConvertTo-UrlEncoded 'abc123' | Should -Be 'abc123'
    }
    It 'Accepts pipeline input' {
        'test value' | ConvertTo-UrlEncoded | Should -Be 'test+value'
    }
}

Describe 'ConvertFrom-UrlEncoded' {
    It 'Decodes plus as space' {
        ConvertFrom-UrlEncoded 'hello+world' | Should -Be 'hello world'
    }
    It 'Decodes percent-encoded characters' {
        ConvertFrom-UrlEncoded 'a%3db%26c%3dd' | Should -Be 'a=b&c=d'
    }
    It 'Roundtrips with ConvertTo-UrlEncoded' {
        $original = 'hello world & more=stuff'
        $original | ConvertTo-UrlEncoded | ConvertFrom-UrlEncoded | Should -Be $original
    }
}

Describe 'ConvertTo-Hash' {
    It 'Returns a SHA256 hash string' {
        $result = ConvertTo-Hash 'hello'
        $result | Should -Not -BeNullOrEmpty
        $result.Length | Should -Be 64
    }
    It 'Returns consistent hash for same input' {
        $h1 = ConvertTo-Hash 'test'
        $h2 = ConvertTo-Hash 'test'
        $h1 | Should -Be $h2
    }
    It 'Returns different hashes for different inputs' {
        $h1 = ConvertTo-Hash 'abc'
        $h2 = ConvertTo-Hash 'def'
        $h1 | Should -Not -Be $h2
    }
}
