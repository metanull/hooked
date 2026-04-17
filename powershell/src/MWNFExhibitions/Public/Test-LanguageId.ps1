function Test-LanguageId {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [AllowEmptyString()]
        [string]$LanguageId
    )

    process {
        return ($LanguageId -match '(?-i:^[a-z]{2}$)')
    }
}