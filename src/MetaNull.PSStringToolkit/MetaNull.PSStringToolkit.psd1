@{
    RootModule        = 'MetaNull.PSStringToolkit.psm1'
    ModuleVersion     = '0.1.2'
    GUID              = '94ba9d26-9cf5-4fde-b708-de4561ecaa66'
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
            Tags         = @('string', 'encoding', 'html', 'url', 'dotenv', 'utility')
            LicenseUri   = 'https://opensource.org/license/mit'
            ProjectUri   = 'https://github.com/metanull/hooked'
            ReleaseNotes = '0.1.2: Refresh module GUID and continue PSGallery metadata cleanup.'
        }
    }
}
