Function Test-LeafName {
    <#
        .Synopsis
            Test if a string is valid as a file name (no path separators or invalid chars).
        .Example
            'Azerty\uiop.txt' | Test-LeafName   # Returns: $False
        .Example
            'uiop.txt' | Test-LeafName           # Returns: $True
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [Alias('Leaf')]
        [AllowEmptyString()]
        [String]$Name
    )
    Process {
        $Name -notmatch ('[{0}]' -f [Regex]::Escape([IO.Path]::GetInvalidFileNameChars() -join ''))
    }
}
