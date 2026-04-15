Function ConvertTo-Serialized {
    <#
        .Synopsis
            Serialize an object to XML using PowerShell serialization
        .Example
            @{a=1;b=2} | ConvertTo-Serialized
    #>
    [CmdletBinding()]
    [OutputType([String])]
    param (
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
        [Object]$InputObject
    )
    Begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"
        [string]$OutputString = ""
    }
    Process {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Serializing to XML"
        $OutputString = [System.Management.Automation.PSSerializer]::Serialize($InputObject)
    }
    End {
        $OutputString | Write-Output
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}
