Function ConvertTo-HtmlTable {
    <#
        .Synopsis
            Transform an array or hashtable into an HTML table.
        .Description
            Transform an array or hashtable into an HTML table.
            - If Headings provided add a Headings Line
            - If Data is a Hashtable use its Key as Heading Row
            - If Array elements are array, each become a column
            - If Array elements are hashtables, they become a nested table
        .Example
            @{Name='Pascal';Role='Dev'} | ConvertTo-HtmlTable
        .Example
            @('a','b','c') | ConvertTo-HtmlTable -Headings @('Letter') -Encode
    #>
    [CmdletBinding()]
    [OutputType([String])]
    param (
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
        [Alias('Content')]
        $InputObject,

        [Parameter(Position = 1)]
        [array]$Headings,

        [Alias('Convert')]
        [switch]$Encode
    )
    Begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"
        [string[]]$LineArray = ,@()
    }
    Process {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        if ($null -ne $Headings) {
            $line = ("<th>{0}</th>" -f (($Headings | ForEach-Object { if ($Encode) { $_ | ConvertTo-HtmlEncoded } else { $_ } }) -join '</th><th>' ))
            $LineArray += ("<tr>{0}</tr>" -f $line)
        }
        if ($InputObject -is [hashtable] -or $InputObject -is [System.Collections.Specialized.OrderedDictionary]) {
            foreach ($n in $InputObject.GetEnumerator()) {
                $line = ("<th>{0}</th>" -f (($n.Key | ForEach-Object { if ($_ -and $Encode) { $_ | ConvertTo-HtmlEncoded } else { $_ } }) -join '</th><th>' ))
                $line += ("<td>{0}</td>" -f (($n.Value | ForEach-Object { if ($_ -and $Encode) { $_ | ConvertTo-HtmlEncoded } else { $_ } }) -join '</td><td>' ))
                $LineArray += ("<tr>{0}</tr>" -f $line)
            }
        } else {
            $InputObject | ForEach-Object {
                $line = ("<td>{0}</td>" -f (($_ | ForEach-Object { if ($_ -and $Encode) { $_ | ConvertTo-HtmlEncoded } else { $_ } }) -join '</td><td>' ))
                $LineArray += ("<tr>{0}</tr>" -f $line)
            }
        }
    }
    End {
        ("<table><tbody>{0}</tbody></table>" -f ($LineArray -join '')) | Write-Output
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}
