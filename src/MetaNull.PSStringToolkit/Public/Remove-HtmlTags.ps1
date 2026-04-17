Function Remove-HtmlTags {
    <#
        .Synopsis
            Convert an HTML string to plain text by stripping tags.
        .Example
            '<p>Hello World</p>' | Remove-HtmlTags
            # Returns: Hello World
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Justification = 'Tags refers to HTML tags, plural is correct')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'This function does not change system state, it transforms a string')]
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(ValueFromPipeline = $true, Position = 0, Mandatory = $false)]
        [string]$HtmlInput
    )
    Begin {
        $OutputString = [string]::Empty
    }
    Process {
        $OutputString = ($HtmlInput | ConvertTo-WellFormedXml | Select-Xml -XPath '/xml/p').Node.InnerText
    }
    End {
        return $OutputString
    }
}
