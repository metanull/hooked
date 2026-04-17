Function ConvertFrom-DotEnv {
    <#
        .Synopsis
            Parse .env file lines into an ordered dictionary.
        .Description
            Parses KEY=VALUE lines (with optional quoting), skips comments and blank lines.
            Throws on malformed lines.
        .Example
            Get-Content '.env' | ConvertFrom-DotEnv
    #>
    [CmdletBinding()]
    [OutputType([System.Collections.Specialized.OrderedDictionary])]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [AllowEmptyString()]
        [string[]]$DotEnv
    )
    Begin {
        $OutputTable = [ordered]@{}
    }
    Process {
        $DotEnv | Where-Object { $_ -ne [string]::Empty -and $_ -notmatch '^\s*#' } | ForEach-Object {

            # REGEX for empty/blank/comment lines
            $EMPTY = '^\s*(?:(#.*)?)$'

            # REGEX to parse a .env line
            $REGEX = '^\s*([\w]+)\s*=\s*(?=(["'']?))\2(.*?)(?<!\\{1,3,5})\2\s*$'

            if ($_ -match $EMPTY) {
                return
            }
            if ($_ -notmatch $REGEX) {
                throw "Invalid .env line: $($_)"
            }

            $Key   = $Matches[1]
            $Value = $Matches[3]

            if ($OutputTable.Contains($Key)) {
                Write-Warning -Message "Duplicated key in .env, only the last value is kept: $($_)"
                $OutputTable.Remove($Key)
            }

            $OutputTable += @{ $Key = $Value }
        }
    }
    End {
        return $OutputTable
    }
}
