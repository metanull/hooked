BeforeAll {
    $ModulePath = Join-Path $PSScriptRoot '..\..\src\MetaNull.PSStringToolkit\MetaNull.PSStringToolkit.psd1'
    Import-Module $ModulePath -Force
}

Describe 'ConvertTo-HtmlEncoded' {
    It 'Encodes angle brackets' {
        ConvertTo-HtmlEncoded '<div>' | Should -Be '&lt;div&gt;'
    }
    It 'Encodes ampersand' {
        ConvertTo-HtmlEncoded 'A & B' | Should -Be 'A &amp; B'
    }
    It 'Passes plain text through unchanged' {
        ConvertTo-HtmlEncoded 'Hello World' | Should -Be 'Hello World'
    }
    It 'Handles empty string' {
        ConvertTo-HtmlEncoded '' | Should -Be ''
    }
    It 'Accepts pipeline input' {
        '<b>' | ConvertTo-HtmlEncoded | Should -Be '&lt;b&gt;'
    }
}

Describe 'ConvertFrom-HtmlEncoded' {
    It 'Decodes angle brackets' {
        ConvertFrom-HtmlEncoded '&lt;div&gt;' | Should -Be '<div>'
    }
    It 'Decodes ampersand' {
        ConvertFrom-HtmlEncoded 'A &amp; B' | Should -Be 'A & B'
    }
    It 'Passes plain text through unchanged' {
        ConvertFrom-HtmlEncoded 'Hello World' | Should -Be 'Hello World'
    }
    It 'Roundtrips with ConvertTo-HtmlEncoded' {
        $original = '<p class="test">Hello & World</p>'
        $original | ConvertTo-HtmlEncoded | ConvertFrom-HtmlEncoded | Should -Be $original
    }
}

Describe 'ConvertTo-HtmlTime' {
    It 'Returns a time tag with formatted date' {
        $result = ConvertTo-HtmlTime -InputDate ([datetime]'2024-01-15')
        $result | Should -BeLike '*<time datetime="2024-01-15"*'
        $result | Should -BeLike '*<p>*</p>*'
    }
}

Describe 'ConvertTo-HtmlTable' {
    It 'Converts hashtable to HTML table' {
        $result = @{Name = 'Pascal'} | ConvertTo-HtmlTable
        $result | Should -BeLike '*<table>*<th>*Name*</th>*<td>*Pascal*</td>*</table>*'
    }
    It 'Converts array to HTML table' {
        $result = @('a', 'b') | ConvertTo-HtmlTable
        $result | Should -BeLike '*<table>*<td>*a*</td>*</table>*'
    }
    It 'Adds headings when provided' {
        $result = @('val') | ConvertTo-HtmlTable -Headings @('Col1')
        $result | Should -BeLike '*<th>Col1</th>*'
    }
    It 'Encodes values when -Encode is set' {
        $result = @{Key = '<b>bold</b>'} | ConvertTo-HtmlTable -Encode
        $result | Should -BeLike '*&lt;b&gt;*'
    }
}

Describe 'Remove-HtmlTags' {
    It 'Strips tags from simple HTML' {
        '<p>Hello World</p>' | Remove-HtmlTags | Should -Be 'Hello World'
    }
}
