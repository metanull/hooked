function Build-NodeJSClient {
    <#
        .SYNOPSIS
            Update a JavaScript/Node.js client application.
        .DESCRIPTION
            Wraps Invoke-WebAppUpdate with Node.js-specific build steps:
            - Clean node_modules
            - npm install
            - npm audit fix + update browserslist
            - npm run build
            - Deploy dist/ to ../client-dist/
        .PARAMETER Directory
            Path to the Node.js application directory.
        .PARAMETER Branch
            Git branch name.
        .PARAMETER Alias
            Display name for the application.
        .PARAMETER Url
            The application URL (for display purposes).
        .PARAMETER MutexName
            Mutex name for single-execution guard.
        .PARAMETER Force
            If set, always reset and pull.
        .PARAMETER LogFile
            Path to the log file.
        .PARAMETER SmtpServer
            SMTP server for notifications.
        .PARAMETER SmtpFrom
            Sender address for notifications.
        .PARAMETER To
            Recipient(s) for notifications.
        .PARAMETER Cc
            CC recipient(s) for notifications.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]  [string]$Directory,
        [Parameter(Mandatory = $true)]  [string]$Branch,
        [Parameter(Mandatory = $true)]  [string]$Alias,
        [Parameter(Mandatory = $true)]  [string]$Url,
        [Parameter(Mandatory = $false)] [string]$MutexName = 'WebAppUpdateMutex',
        [Parameter(Mandatory = $false)] [switch]$Force,
        [Parameter(Mandatory = $false)] [string]$LogFile,
        [Parameter(Mandatory = $false)] [string]$SmtpServer,
        [Parameter(Mandatory = $false)] [string]$SmtpFrom,
        [Parameter(Mandatory = $false)] [string[]]$To,
        [Parameter(Mandatory = $false)] [string[]]$Cc
    )
    Process {
        $arguments = @{}
        foreach ($key in $PSBoundParameters.Keys) { $arguments[$key] = $PSBoundParameters[$key] }
        $arguments['ScriptBlock'] = [ordered]@{
            CleaningUp = {
                Write-Verbose '> Cleaning up'
                Remove-Item -Force -Recurse .\node_modules\ -ErrorAction Continue 2>&1
            }
            Installing = {
                Write-Verbose '> Installing'
                npm install 2>&1
            }
            Updating   = {
                Write-Verbose '> Updating dependencies'
                npm audit fix 2>&1
                npx update-browserslist-db 2>&1
            }
            Building   = {
                Write-Verbose '> Building'
                npm run build 2>&1
            }
            Deploying  = {
                if (Test-Path -Path 'dist') {
                    Write-Verbose '> Deploying'
                    if (Test-Path -Path '..\.htaccess') {
                        Copy-Item '..\.htaccess' 'dist\.htaccess'
                    }
                    Remove-Item '..\client-dist' -Recurse -ErrorAction SilentlyContinue
                    Copy-Item 'dist' -Destination '..\client-dist' -Recurse
                }
            }
        }
        Invoke-WebAppUpdate @arguments
    }
}
