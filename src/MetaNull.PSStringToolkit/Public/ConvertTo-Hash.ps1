Function ConvertTo-Hash {
    <#
        .Synopsis
            Convert a string to a SHA256 hash
        .Example
            'hello' | ConvertTo-Hash
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
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Computing HASH for string"
        $stringAsStream = [System.IO.MemoryStream]::new()
        $writer = [System.IO.StreamWriter]::new($stringAsStream)
        $writer.Write($InputString)
        $writer.Flush()
        $stringAsStream.Position = 0
        $OutputString = (Get-FileHash -InputStream $stringAsStream | Select-Object Hash).Hash
    }
    End {
        $OutputString | Write-Output
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}
