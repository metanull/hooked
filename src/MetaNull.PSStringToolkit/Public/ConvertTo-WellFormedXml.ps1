Function ConvertTo-WellFormedXml {
    <#
        .Synopsis
            Convert a fragment of well-formed HTML into a well-formed XML document.
        .Description
            Wraps the input in an XML envelope with HTML entity declarations,
            then parses it into an XDocument.
        .Example
            '<p>Hello</p>' | ConvertTo-WellFormedXml
    #>
    [CmdletBinding()]
    [OutputType([System.Xml.Linq.XDocument])]
    param (
        [Parameter(Position = 0, ValueFromPipeline = $true)]
        [string]$InputConflunceHtmlString = [String]::Empty
    )
    Begin {
        [System.Xml.Linq.XDocument]$OutputXml = [System.Xml.Linq.XDocument]::Empty
    }
    Process {
        $HtmlEntities = 'nbsp','rarr','larr','uarr','darr','nwarr','nearr','swarr','searr','spades','clubs','hearts','diams','hellip','lsquo','rsquo','sbquo','ldquo','rdquo','bdquo','lsaquo','rsaquo','laquo','raquo','copy','trade','quot','ndash','mbash','aacute','agrave','acirc','auml','aring','atilde','eacute','egrave','ecirc','euml','iacute','igrave','icirc','iuml','ntilde','oacute','ograve','ocirc','ouml','otilde','uacute','ugrave','ucirc','uuml','szlig','aelig','ccedil','brvbar','Ntilde','acute'
        $HtmlEntityList = '<!ENTITY {0} "">' -f ($HtmlEntities -join ' ""><!ENTITY ')
        $InputXml = ('<!DOCTYPE xml [ {0} ]><xml xmlns:metanull="https://bitbucket.org/metanull">{1}</xml>' -f $HtmlEntityList, $InputConflunceHtmlString)
        $OutputXml = [System.Xml.Linq.XDocument]::Parse($InputXml)
    }
    End {
        return $OutputXml
    }
}
