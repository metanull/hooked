Function ConvertTo-UrlEncoded {
    <#
        .Synopsis
            Convert a string to URL Encoded format
        .Example
            'hello world' | ConvertTo-UrlEncoded
            # Returns: hello+world
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
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Encoding string to URL"
        $OutputString = [System.Web.HttpUtility]::UrlEncode($InputString)
    }
    End {
        $OutputString | Write-Output
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}
