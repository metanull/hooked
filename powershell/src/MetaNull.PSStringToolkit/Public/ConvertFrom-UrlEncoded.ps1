Function ConvertFrom-UrlEncoded {
    <#
        .Synopsis
            Decode a URL encoded string back to plain text
        .Example
            'hello+world' | ConvertFrom-UrlEncoded
            # Returns: hello world
    #>
    [CmdletBinding()]
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
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Decoding URL string"
        $OutputString = [System.Web.HttpUtility]::UrlDecode($InputString)
    }
    End {
        $OutputString | Write-Output
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}
