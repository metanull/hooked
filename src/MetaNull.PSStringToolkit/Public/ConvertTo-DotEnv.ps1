Function ConvertTo-DotEnv {
    <#
        .Synopsis
            Generate .env file lines from a hashtable, ordered dictionary, or PSCustomObject.
        .Example
            @{APP_NAME='MyApp'; APP_URL='http://localhost'} | ConvertTo-DotEnv
    #>
    [CmdletBinding(DefaultParameterSetName = "hashtable")]
    [OutputType([string[]])]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ParameterSetName = "hashtable")]
        [hashtable]$Table,

        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ParameterSetName = "dictionary")]
        [System.Collections.Specialized.OrderedDictionary]$Dictionary,

        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ParameterSetName = "pscustomobject")]
        [pscustomobject]$Object
    )
    Begin {
        $OutputStringArray = @()
    }
    Process {
        if ($Dictionary) {
            $DotEnv = $Dictionary
        } elseif ($Object) {
            $DotEnv = [ordered]@{}
            $Object.PSObject.Properties | ForEach-Object { $DotEnv[$_.Name] = $_.Value }
        } else {
            $DotEnv = $Table
        }
        $DotEnv.Keys | ForEach-Object {
            $OutputStringArray += ('{0}="{1}"' -f $_, ($DotEnv.$_))
        }
    }
    End {
        return [string[]]$OutputStringArray
    }
}
