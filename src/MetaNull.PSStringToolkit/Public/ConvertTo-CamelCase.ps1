Function ConvertTo-CamelCase {
    <#
        .Synopsis
            Convert a string to CamelCase (TitleCase with non-word chars removed)
        .Example
            'hello world 123' | ConvertTo-CamelCase
            # Returns: HelloWorld123
    #>
    [CmdletBinding()]
    [OutputType([String])]
    param (
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
        [string]$InputString
    )
    Begin {
        [String]$OutputString = [String]::Empty
    }
    Process {
        $OutputString = (Get-Culture).TextInfo.ToTitleCase($InputString) -Replace '\W'
    }
    End {
        return $OutputString
    }
}
