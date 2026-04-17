BeforeAll {
    $ModulePath = Join-Path $PSScriptRoot '..\..\src\MetaNull.PSStringToolkit\MetaNull.PSStringToolkit.psd1'
    Import-Module $ModulePath -Force
}

Describe 'Test-LeafName' {
    It 'Returns true for valid filename' {
        'myfile.txt' | Test-LeafName | Should -Be $true
    }
    It 'Returns false for path with backslash' {
        'path\file.txt' | Test-LeafName | Should -Be $false
    }
    It 'Returns false for path with forward slash' {
        'path/file.txt' | Test-LeafName | Should -Be $false
    }
    It 'Returns true for empty string' {
        '' | Test-LeafName | Should -Be $true
    }
    It 'Returns false for characters invalid in filenames' {
        'file<name>.txt' | Test-LeafName | Should -Be $false
    }
}

Describe 'ConvertTo-LeafName' {
    It 'Replaces backslash with empty string by default' {
        'ui\op.txt' | ConvertTo-LeafName | Should -Be 'uiop.txt'
    }
    It 'Replaces with custom character' {
        'ui\op.txt' | ConvertTo-LeafName -ReplaceBy '_' | Should -Be 'ui_op.txt'
    }
    It 'Replaces with empty string' {
        'ui\op.txt' | ConvertTo-LeafName -ReplaceBy '' | Should -Be 'uiop.txt'
    }
    It 'Returns valid filename unchanged' {
        'valid.txt' | ConvertTo-LeafName | Should -Be 'valid.txt'
    }
}
