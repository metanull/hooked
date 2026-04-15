Function ConvertTo-CamelCaseKeys {
    <#
        .Synopsis
            Convert all keys of a HashTable to CamelCase
        .Example
            @{'hello-world'=42} | ConvertTo-CamelCaseKeys
            # Returns: @{HelloWorld=42}
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Justification = 'Keys refers to hashtable keys, plural is correct')]
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
        [hashtable]$InputHashTable
    )
    Begin {
        [hashtable]$OutputHashTable = @{}
    }
    Process {
        foreach ($k in $InputHashTable.Keys) {
            $OutputHashTable += @{ ($k | ConvertTo-CamelCase) = $InputHashTable.$k }
        }
    }
    End {
        return $OutputHashTable
    }
}
