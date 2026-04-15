Function Test-IsExpired {
    <#
        .Synopsis
            Check if a date is older than N minutes from now.
        .Description
            Compare the current time with a DateTime or date string, checking if
            more than the specified number of minutes have elapsed (i.e. is expired).
        .Parameter Date
            A DateTime object
        .Parameter DateString
            A date/time string (e.g. '20240115120000')
        .Parameter DateStringFormat
            Format of DateString (default: 'yyyyMMddHHmmss')
        .Parameter Minutes
            TTL in minutes after which the date is considered expired
        .Example
            $fiveMinutesAgo = (Get-Date).AddMinutes(-5)
            Test-IsExpired -Date $fiveMinutesAgo -Minutes 3
            # Returns: $true (5 min ago > 3 min TTL)
        .Example
            $fiveMinutesAgo = (Get-Date).AddMinutes(-5)
            Test-IsExpired -Date $fiveMinutesAgo -Minutes 10
            # Returns: $false (5 min ago < 10 min TTL)
    #>
    [CmdletBinding(DefaultParameterSetName = 'datetime')]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = 'datetime')]
        [datetime]$Date,

        [Parameter(Mandatory = $true, ParameterSetName = 'datestring')]
        [string]$DateString,
        [Parameter(Mandatory = $false, ParameterSetName = 'datestring')]
        [string]$DateStringFormat = 'yyyyMMddHHmmss',

        [Parameter(Mandatory = $false)]
        [int]$Minutes = 0
    )
    Begin {
        $expired = $true
    }
    Process {
        switch ($PsCmdlet.ParameterSetName) {
            "datetime" {
                $DateTime = $Date
            }
            "datestring" {
                $DateTime = [datetime]::ParseExact($DateString, $DateStringFormat, $null)
            }
        }
        $Span = New-TimeSpan -Minutes $Minutes
        if ((Get-Date) -le $DateTime + $Span) {
            $expired = $false
        }
    }
    End {
        return $expired
    }
}
