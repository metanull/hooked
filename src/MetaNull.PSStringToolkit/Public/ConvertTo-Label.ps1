Function ConvertTo-Label {
    <#
        .Synopsis
            Convert a string to a label format.
        .Description
            Convert a string to a label:
            - Made of lower case alphanumerical characters separated by single dashes
            - Always starts by a letter
            - No trailing dashes at the end
            Can optionally convert &|.@ characters to their text representation
        .Example
            "SC.IIT.DIS.3" | ConvertTo-Label
        .Example
            "pascal.havelange@eesc.europa.eu" | ConvertTo-Label -ReplacePunctuation
    #>
    [CmdletBinding()]
    [OutputType([String])]
    param (
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
        [string]$InputString,

        [switch]$ReplacePunctuation
    )
    Begin {
        [string]$OutputString = ""
    }
    Process {
        # Remove non ASCII (mind the "C" in "-creplace")
        $OutputString = ($InputString -creplace "\P{IsBasicLatin}")

        if ($ReplacePunctuation) {
            $OutputString = ($OutputString -replace "(\s*\.+\s*)+"," dot ")
            $OutputString = ($OutputString -replace "(\s*[&]+\s*)+"," and ")
            $OutputString = ($OutputString -replace "(\s*[\|]+\s*)+"," or ")
            $OutputString = ($OutputString -replace "(\s*[@]+\s*)+"," at ")
        }
        # Remove non alnum characters
        $OutputString = ($OutputString -replace "[\W]+","-")
        # Remove head/tail dashes, remove head numbers
        $OutputString = ($OutputString -replace "(^[\d-]*|[-]*$)")
    }
    End {
        $OutputString.ToLower() | Write-Output
    }
}
