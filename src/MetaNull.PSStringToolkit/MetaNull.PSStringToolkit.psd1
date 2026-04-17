@{
    RootModule        = 'MetaNull.PSStringToolkit.psm1'
    ModuleVersion     = '0.1.0'
    GUID              = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
    Author            = 'Pascal Havelange'
    CompanyName       = 'Museum With No Frontiers'
    Copyright         = '(c) Museum With No Frontiers. All rights reserved.'
    Description       = 'String encoding, conversion, placeholder expansion, .env parsing, and filename validation utilities.'
    PowerShellVersion = '5.1'
    FunctionsToExport = @(
        'Remove-HtmlTags',
        'ConvertTo-HtmlTime',
        'ConvertTo-HtmlTable',
        'ConvertTo-HtmlEncoded',
        'ConvertFrom-HtmlEncoded',
        'ConvertTo-UrlEncoded',
        'ConvertFrom-UrlEncoded',
        'ConvertTo-Hash',
        'ConvertTo-CamelCase',
        'ConvertTo-CamelCaseKeys',
        'ConvertTo-CamelCaseList',
        'ConvertTo-WellFormedXml',
        'ConvertTo-Serialized',
        'ConvertFrom-Serialized',
        'ConvertTo-Label',
        'Expand-String',
        'ConvertFrom-DotEnv',
        'ConvertTo-DotEnv',
        'ConvertTo-NullableJsonArray',
        'Test-IsExpired',
        'Test-LeafName',
        'ConvertTo-LeafName',
        'Select-Join'
    )
    CmdletsToExport   = @()
    VariablesToExport  = @()
    AliasesToExport    = @()
    PrivateData       = @{
        PSData = @{
            Tags       = @('string', 'encoding', 'html', 'url', 'dotenv', 'utility')
            LicenseUri = 'https://github.com/metanull/hooked/blob/main/LICENSE'
            ProjectUri = 'https://github.com/metanull/hooked'
        }
    }
}
