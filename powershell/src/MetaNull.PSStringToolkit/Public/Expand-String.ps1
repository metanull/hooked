Function Expand-String {
    <#
        .Synopsis
            Expand placeholders in a string using one or more data sets.
        .Description
            Look for {PlaceholderName} tokens in a string and replace them
            with values found in one or more data sets. Datasets are evaluated
            in order. The special token {EmptyString} is replaced with ''.
        .Example
            $set1 = [pscustomobject]@{Lastname='Havelange'; Firstname='Pascal'}
            $set2 = [pscustomobject]@{Version='1.0'; Application='MWNFPS'}
            $string = 'Hello {Firstname} {Lastname}. Welcome to {Application} v{Version}'
            Expand-String -InputString $string -ValueSets @($set1, $set2)
            # Returns: Hello Pascal Havelange. Welcome to MWNFPS v1.0
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
        [AllowEmptyString()]
        [string]$InputString,

        [Parameter(Position = 1, Mandatory = $true)]
        [object[]]$ValueSets
    )
    Begin {
        $OutputString = [string]::Empty
    }
    Process {
        $OutputString = $InputString

        # Run the loop as long as there are placeholders, max iterations = number of value sets
        for ($iter = 0; $iter -lt $ValueSets.Count; $iter++) {
            $PlaceHolders = ([regex]'(?<=\{)(.*?)(?=\})').Matches($OutputString)
            if (-not $PlaceHolders) {
                break
            }
            $PlaceHolders | ForEach-Object {
                if ($_.Value -eq 'EmptyString') {
                    $OutputString = $OutputString.Replace('{EmptyString}', '')
                } else {
                    foreach ($ValueSet in $ValueSets) {
                        if ($ValueSet.($_.Value)) {
                            $Needle = '{{{0}}}' -f $_.Value
                            $Replacement = $ValueSet.($_.Value)
                            $OutputString = $OutputString.Replace($Needle, $Replacement)
                            break
                        }
                    }
                }
            }
        }
        return $OutputString
    }
}
