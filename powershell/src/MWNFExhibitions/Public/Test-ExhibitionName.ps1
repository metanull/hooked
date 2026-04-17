function Test-ExhibitionName {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [AllowEmptyString()]
        [string]$Name
    )

    process {
        return ($Name -match '(?-i:^[a-z][a-z0-9_-]+[a-z]$)')
    }
}