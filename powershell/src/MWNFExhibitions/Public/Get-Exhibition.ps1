function Get-Exhibition {
    [CmdletBinding(DefaultParameterSetName = 'param')]
    [OutputType([pscustomobject])]
    param(
        [Parameter(ParameterSetName = 'param', Position = 0, Mandatory = $false)]
        [ValidateScript({ Test-ExhibitionName -Name $_ })]
        [string]$Name,

        [Parameter(ParameterSetName = 'param', Position = 1, Mandatory = $false)]
        [ValidateScript({ Test-LanguageId -LanguageId $_ })]
        [string]$LanguageId,

        [Parameter(ParameterSetName = 'template', Position = 0, Mandatory = $true)]
        [switch]$Template
    )

    $server = Import-ExhibitionServerConfiguration

    if ($Template) {
        return [pscustomobject]@{
            ApiEnvironment    = $server.ApiEnvironment
            ClientEnvironment = $server.ClientEnvironment
        }
    }

    if (($PSBoundParameters.ContainsKey('Name') -and -not $PSBoundParameters.ContainsKey('LanguageId')) -or
        ($PSBoundParameters.ContainsKey('LanguageId') -and -not $PSBoundParameters.ContainsKey('Name'))) {
        throw 'Name and LanguageId must be provided together.'
    }

    if ($PSBoundParameters.ContainsKey('Name')) {
        return ($server.Exhibitions | Where-Object { $_.Name -eq $Name -and $_.LanguageId -eq $LanguageId } | Select-Object Name, LanguageId, ApiEnvironment, ClientEnvironment, Path, Status)
    }

    return ($server.Exhibitions | Select-Object Name, LanguageId, Status)
}