function Send-DeployMail {
    <#
        .SYNOPSIS
            Send an email message via SMTP.
        .DESCRIPTION
            Sends an HTML email. SMTP settings (server, from, to, cc) are read from the
            registry Settings key under the configured registry root, but can be overridden
            via parameters.
        .PARAMETER Subject
            Subject of the email.
        .PARAMETER Body
            Body of the email (HTML).
        .PARAMETER To
            Recipient(s). Overrides registry-configured recipients.
        .PARAMETER Cc
            CC recipient(s). Overrides registry-configured CC.
        .PARAMETER SmtpServer
            SMTP server. Overrides registry-configured server.
        .PARAMETER From
            Sender address. Overrides registry-configured sender.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [string]$Subject,

        [Parameter(Position = 1, Mandatory = $true, ValueFromPipeline = $true)]
        [AllowEmptyString()]
        [string[]]$Body,

        [Parameter(Mandatory = $false)]
        [string[]]$To,

        [Parameter(Mandatory = $false)]
        [string[]]$Cc,

        [Parameter(Mandatory = $false)]
        [string]$SmtpServer,

        [Parameter(Mandatory = $false)]
        [string]$From
    )
    Begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        # Try to read defaults from registry
        $SettingsPath = Join-Path $script:DeployQueueConfig.RegistryRoot 'Settings'
        $RegSmtpServer = $null
        $RegSmtpFrom = $null
        $RegSmtpTo = $null
        $RegSmtpCc = $null
        if (Test-Path $SettingsPath) {
            $HiveSettings = Get-ItemProperty -Path $SettingsPath
            $RegSmtpServer = $HiveSettings | ForEach-Object { $_.SmtpServer } 2>$null
            $RegSmtpFrom = $HiveSettings | ForEach-Object { $_.SmtpFrom } 2>$null
            $RegSmtpTo = $HiveSettings | ForEach-Object { $_.SmtpTo } 2>$null
            $RegSmtpCc = $HiveSettings | ForEach-Object { $_.SmtpCc } 2>$null
        }
    }
    End {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
    Process {
        $EffectiveSmtpServer = if ($PSBoundParameters.ContainsKey('SmtpServer')) { $SmtpServer } else { $RegSmtpServer }
        $EffectiveFrom = if ($PSBoundParameters.ContainsKey('From')) { $From } else { $RegSmtpFrom }
        $EffectiveTo = if ($PSBoundParameters.ContainsKey('To')) { $To } elseif ($RegSmtpTo) { @($RegSmtpTo) } else { $null }
        $EffectiveCc = if ($PSBoundParameters.ContainsKey('Cc')) { $Cc } elseif ($RegSmtpCc) { @($RegSmtpCc) } else { $null }

        if ($EffectiveSmtpServer -and $EffectiveFrom) {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Sending email as $EffectiveFrom, using $EffectiveSmtpServer."
            $MailMessage = @{
                Subject                  = $Subject
                Body                     = $Body -join [System.Environment]::NewLine
                From                     = $EffectiveFrom
                To                       = $EffectiveTo
                Priority                 = 'Low'
                SmtpServer               = $EffectiveSmtpServer
                DeliveryNotificationOption = 'OnFailure'
                BodyAsHtml               = $true
            }
            if ($EffectiveCc) {
                $MailMessage['Cc'] = $EffectiveCc
            }
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] $($MailMessage.Body)"
            Send-MailMessage @MailMessage
        } else {
            Write-Error "SmtpServer and/or From are not defined! Configure via registry or pass as parameters."
        }
    }
}
