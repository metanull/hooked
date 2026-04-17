Function ConvertTo-HtmlTime {
    <#
        .Synopsis
            Transform a DateTime object into an HTML Time tag.
        .Example
            Get-Date '2024-01-15' | ConvertTo-HtmlTime
    #>
    [CmdletBinding()]
    [OutputType([String])]
    param (
        [Parameter(Position = 0, ValueFromPipeline = $true)]
        [Alias('Content')]
        [DateTime]$InputDate = (Get-Date)
    )
    Begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"
        [string]$StringOutput = ''
    }
    Process {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"
        $StringOutput += "<p><time datetime=`"{0}`"/>&nbsp;</p>" -f (("{0:yyyy-MM-dd}" -f ($InputDate)) | ConvertTo-HtmlEncoded)
    }
    End {
        $StringOutput | Write-Output
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}
