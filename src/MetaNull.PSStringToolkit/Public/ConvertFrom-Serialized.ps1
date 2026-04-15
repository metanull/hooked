Function ConvertFrom-Serialized {
    <#
        .Synopsis
            Deserialize an object from PowerShell XML serialization
        .Example
            $xml | ConvertFrom-Serialized
    #>
    [CmdletBinding()]
    [OutputType([Object])]
    param (
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
        [string]$InputString
    )
    Begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"
        [Object]$OutputObject = $null
    }
    Process {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Deserializing from XML"
        $OutputObject = [System.Management.Automation.PSSerializer]::Deserialize($InputString)
    }
    End {
        $OutputObject | Write-Output
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}
