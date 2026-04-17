Function ConvertTo-LeafName {
    <#
        .Synopsis
            Replace all invalid filename characters with a replacement character.
        .Example
            'ui\a/op.txt' | ConvertTo-LeafName -ReplaceBy ''
            # Returns: 'uiaop.txt'
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [Alias('Leaf')]
        [String]$Name,

        [Parameter(Mandatory = $false, Position = 1)]
        [Alias('Replace')]
        [AllowEmptyString()]
        [String]$ReplaceBy = [string]::Empty
    )
    Process {
        $Replacement = '-'
        if (Test-LeafName -Name $ReplaceBy) {
            $Replacement = $ReplaceBy
        }
        $Name -replace ('[{0}]' -f [Regex]::Escape([IO.Path]::GetInvalidFileNameChars() -join '')), $Replacement
    }
}
