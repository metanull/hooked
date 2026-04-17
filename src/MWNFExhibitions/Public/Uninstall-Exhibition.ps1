function Uninstall-Exhibition {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [ValidateScript({ Test-ExhibitionName -Name $_ })]
        [string]$Name,

        [Parameter(Position = 1, Mandatory = $true)]
        [ValidateScript({ Test-LanguageId -LanguageId $_ })]
        [string]$LanguageId,

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    $registryRoot = Initialize-ExhibitionServerRegistry
    $exhibitionPath = Join-Path (Join-Path $registryRoot 'Exhibitions') (('{0}.{1}' -f $Name, $LanguageId))

    if (-not (Test-Path -Path $exhibitionPath)) {
        throw "Exhibition '$Name.$LanguageId' does not exist."
    }

    Remove-Item -Path $exhibitionPath -Recurse -Force -ErrorAction Stop

    return [pscustomobject]@{
        Result     = 'Success'
        Name       = $Name
        LanguageId = $LanguageId
    }
}