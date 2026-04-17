Function ConvertTo-CamelCaseList {
    <#
        .Synopsis
            Convert all values of a string array to CamelCase
        .Example
            @('hello-world','hello world') | ConvertTo-CamelCaseList
            # Returns: @('HelloWorld','HelloWorld')
    #>
    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
        [string[]]$InputList
    )
    Begin {
        [string[]]$OutputList = @()
    }
    Process {
        foreach ($v in $InputList) {
            $OutputList += ($v | ConvertTo-CamelCase)
        }
    }
    End {
        return $OutputList
    }
}
