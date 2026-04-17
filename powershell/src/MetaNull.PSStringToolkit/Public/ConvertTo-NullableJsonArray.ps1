Function ConvertTo-NullableJsonArray {
    <#
        .Synopsis
            Convert an object or array to a JSON array string, or return $null if empty.
        .Example
            @('a','b') | ConvertTo-NullableJsonArray
            # Returns: '["a","b"]'
        .Example
            $null | ConvertTo-NullableJsonArray
            # Returns: $null
    #>
    [CmdletBinding(DefaultParameterSetName = 'Object')]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $false, ValueFromPipeline = $true, Position = 0, ParameterSetName = 'Object')]
        [AllowEmptyCollection()]
        [AllowEmptyString()]
        [AllowNull()]
        [Object]$Object,

        [Parameter(Mandatory = $false, ValueFromPipeline = $true, Position = 0, ParameterSetName = 'Variable')]
        [AllowEmptyCollection()]
        [AllowEmptyString()]
        [AllowNull()]
        [String]$Variable
    )
    Begin {}
    End {}
    Process {
        if ($PsCmdlet.ParameterSetName -eq 'Variable') {
            $Object = Get-Variable -Name $Variable -ValueOnly -ErrorAction SilentlyContinue
        }
        if ($Object -is [array] -and $Object.Count -gt 1) {
            ConvertTo-Json $Object
        } elseif ($Object) {
            ConvertTo-Json (@() + ($Object))
        } else {
            $null
        }
    }
}
