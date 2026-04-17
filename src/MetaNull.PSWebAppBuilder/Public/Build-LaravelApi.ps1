function Build-LaravelApi {
    <#
        .SYNOPSIS
            Update a PHP/Laravel API application.
        .DESCRIPTION
            Wraps Invoke-WebAppUpdate with Laravel-specific build steps:
            - Production: composer install --no-dev -o + artisan optimize
            - Development (develop branch): composer install (with dev dependencies)
        .PARAMETER Directory
            Path to the Laravel application directory.
        .PARAMETER Branch
            Git branch name. When 'develop', uses dev composer install.
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
            Building   = {
                Write-Verbose '> Building Laravel for Production'
                composer install --no-ansi --prefer-dist --no-dev -o 2>&1
            }
            Optimizing = {
                Write-Verbose '> Optimizing'
                php artisan cache:clear 2>&1
                php artisan view:clear 2>&1
                php artisan config:clear 2>&1
                php artisan optimize 2>&1
            }
        }
        if ($Branch -eq 'develop') {
            $arguments['ScriptBlock']['Building'] = {
                Write-Verbose '> Building Laravel for Development'
                composer install 2>&1
            }
        }
        Invoke-WebAppUpdate @arguments
    }
}
