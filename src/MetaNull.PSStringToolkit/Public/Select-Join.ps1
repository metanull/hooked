Function Select-Join {
    <#
        .Synopsis
            Select from two object lists the items that share a common property (INNER JOIN).
        .Description
            Performs an SQL-like INNER JOIN on two object arrays, matching on a named property.
            Output objects have Left* and Right* prefixed property names.
        .Parameter Left
            The left-side object list
        .Parameter Right
            The right-side object list
        .Parameter On
            The name of the property to join on
        .Example
            $A | Select-Join -Right $B -On Name
        .Example
            Select-Join $A $B Name
    #>
    [CmdletBinding()]
    [OutputType([Object[]])]
    param(
        [Parameter(ValueFromPipeline = $true, Position = 0, Mandatory = $true)]
        [Object[]]$Left,
        [Parameter(Position = 1, Mandatory = $true)]
        [Object[]]$Right,
        [Parameter(Position = 2, Mandatory = $true)]
        [String]$On
    )
    Begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function Started"
        $OutputObjectList = @()
    }
    Process {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"
        $Left | ForEach-Object {
            $L = $_
            $Right | Where-Object { $L.$On -eq $_.$On } | ForEach-Object {
                $R = $_
                $ObjectProperties = @{}
                ($L | Get-Member -MemberType Properties).Name | ForEach-Object {
                    $Name = ('Left{0}' -f $_)
                    $Value = $L.$_
                    $ObjectProperties += @{$Name = $Value}
                }
                ($R | Get-Member -MemberType Properties).Name | ForEach-Object {
                    $Name = ('Right{0}' -f $_)
                    $Value = $R.$_
                    $ObjectProperties += @{$Name = $Value}
                }
                $OutputObjectList += (New-Object PSObject -Property $ObjectProperties)
            }
        }
    }
    End {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function Ended"
        return $OutputObjectList
    }
}
