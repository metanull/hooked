Function ConvertTo-HtmlEncoded {
    <#
        .Synopsis
            Convert a string to HTML Encoded format
        .Example
            'Hello <World>' | ConvertTo-HtmlEncoded
            # Returns: Hello &lt;World&gt;
    #>
    [CmdletBinding()]
    [OutputType([String])]
    param (
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
        [AllowEmptyString()]
        [string]$InputString
    )
    Begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"
        [string]$OutputString = ""
    }
    Process {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Encoding string to HTML"
        $OutputString = [System.Web.HttpUtility]::HtmlEncode($InputString)
    }
    End {
        $OutputString | Write-Output
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}
