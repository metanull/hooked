Function ConvertFrom-HtmlEncoded {
    <#
        .Synopsis
            Decode an HTML encoded string back to plain text
        .Example
            'Hello &lt;World&gt;' | ConvertFrom-HtmlEncoded
            # Returns: Hello <World>
    #>
    [CmdletBinding()]
    [AllowEmptyString()]
    [OutputType([String])]
    param (
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
        [string]$InputString
    )
    Begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"
        [string]$OutputString = ""
    }
    Process {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Decoding HTML string"
        $OutputString = [System.Web.HttpUtility]::HtmlDecode($InputString)
    }
    End {
        $OutputString | Write-Output
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}
