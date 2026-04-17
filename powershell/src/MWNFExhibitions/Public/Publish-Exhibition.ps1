function Publish-Exhibition {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [ValidateScript({ Test-ExhibitionName -Name $_ })]
        [string]$Name,

        [Parameter(Position = 1, Mandatory = $true)]
        [ValidateScript({ Test-LanguageId -LanguageId $_ })]
        [string]$LanguageId,

        [Parameter(Mandatory = $false)]
        [switch]$Demo
    )

    foreach ($commandName in @('git', 'php', 'npm', 'composer', 'robocopy')) {
        Get-Command $commandName -ErrorAction Stop | Out-Null
    }

    $mutex = New-Object System.Threading.Mutex($false, $script:MWNFExhibitionsConfig.PublishMutexName)
    $tempOutput = New-Object System.Collections.Generic.List[string]
    $startTime = Get-Date
    $context = $null

    try {
        if (-not ($mutex.WaitOne($script:MWNFExhibitionsConfig.PublishMutexTimeout))) {
            throw 'Error acquiring publish mutex. The system is busy with another operation.'
        }

        $context = Get-ExhibitionDeploymentContext -Name $Name -LanguageId $LanguageId -Demo:$Demo
        $settings = $context.Settings
        $tempRoot = Expand-ExhibitionString -InputString ([string]$settings.Directory) -Name $Name -LanguageId $LanguageId -ValueSets @($settings, $context.HiveSettings)
        $tempRoot = Join-Path $tempRoot ([string]$settings.DirectoryLeafTemporary)
        if (-not (Test-Path -Path $tempRoot)) {
            New-Item -Path $tempRoot -ItemType Directory -Force | Out-Null
        }

        $apiTempDirectory = Join-Path $tempRoot 'exhibitions-api'
        $clientTempDirectory = Join-Path $tempRoot 'exhibitions-client'

        Set-ExhibitionStatus -ExhibitionPath $context.ExhibitionPath -StatusMessage 'Downloading API'
        Sync-RepositoryWorkingCopy -Directory $apiTempDirectory -Repository ([Uri][string]$settings.ApiRepository) -Branch ([string]$settings.ApiBranch)
        Set-ExhibitionStatus -ExhibitionPath $context.ExhibitionPath -StatusMessage 'Downloading Client'
        Sync-RepositoryWorkingCopy -Directory $clientTempDirectory -Repository ([Uri][string]$settings.ClientRepository) -Branch ([string]$settings.ClientBranch)

        $apiDotEnv = ConvertTo-ExhibitionDotEnvTable -TemplateValues $context.ApiTemplate -Values $context.ApiEnvironment -Settings $settings -HiveSettings $context.HiveSettings -Name $Name -LanguageId $LanguageId
        $clientDotEnv = ConvertTo-ExhibitionDotEnvTable -TemplateValues $context.ClientTemplate -Values $context.ClientEnvironment -Settings $settings -HiveSettings $context.HiveSettings -Name $Name -LanguageId $LanguageId

        Set-ExhibitionStatus -ExhibitionPath $context.ExhibitionPath -StatusMessage 'Building API'
        Set-Content -Path (Join-Path $apiTempDirectory '.env') -Value ($apiDotEnv | ConvertTo-DotEnv) -Force
        Write-LaravelConfigEnvironmentOverrides -Directory $apiTempDirectory -Environment $apiDotEnv
        foreach ($line in (Invoke-ExternalCommand -FilePath 'composer' -ArgumentList @('install', '--no-dev', '--no-ansi') -WorkingDirectory $apiTempDirectory)) { $tempOutput.Add($line) | Out-Null }
        foreach ($line in (Invoke-ExternalCommand -FilePath 'php' -ArgumentList @('artisan', 'key:generate') -WorkingDirectory $apiTempDirectory)) { $tempOutput.Add($line) | Out-Null }
        foreach ($line in (Invoke-ExternalCommand -FilePath 'php' -ArgumentList @('artisan', 'cache:clear') -WorkingDirectory $apiTempDirectory)) { $tempOutput.Add($line) | Out-Null }
        foreach ($line in (Invoke-ExternalCommand -FilePath 'php' -ArgumentList @('artisan', 'config:clear') -WorkingDirectory $apiTempDirectory)) { $tempOutput.Add($line) | Out-Null }
        foreach ($line in (Invoke-ExternalCommand -FilePath 'php' -ArgumentList @('artisan', 'view:clear') -WorkingDirectory $apiTempDirectory)) { $tempOutput.Add($line) | Out-Null }

        $apiTargetDirectory = Expand-ExhibitionString -InputString ([string]$settings.TargetDirectoryApi) -Name $Name -LanguageId $LanguageId -ValueSets @($settings, $context.HiveSettings)
        Set-ExhibitionStatus -ExhibitionPath $context.ExhibitionPath -StatusMessage 'Deploying API'
        foreach ($line in (Copy-DirectoryMirror -Source $apiTempDirectory -Destination $apiTargetDirectory)) { $tempOutput.Add($line) | Out-Null }
        foreach ($line in (Invoke-ExternalCommand -FilePath 'php' -ArgumentList @('artisan', 'optimize') -WorkingDirectory $apiTargetDirectory)) { $tempOutput.Add($line) | Out-Null }

        Set-ExhibitionStatus -ExhibitionPath $context.ExhibitionPath -StatusMessage 'Building Client'
        Set-Content -Path (Join-Path $clientTempDirectory '.env') -Value ($clientDotEnv | ConvertTo-DotEnv) -Force
        foreach ($line in (Invoke-ExternalCommand -FilePath 'npm' -ArgumentList @('install') -WorkingDirectory $clientTempDirectory)) { $tempOutput.Add($line) | Out-Null }
        foreach ($line in (Invoke-ExternalCommand -FilePath 'npm' -ArgumentList @('run', 'build') -WorkingDirectory $clientTempDirectory)) { $tempOutput.Add($line) | Out-Null }

        $clientTargetDirectory = Expand-ExhibitionString -InputString ([string]$settings.TargetDirectoryClient) -Name $Name -LanguageId $LanguageId -ValueSets @($settings, $context.HiveSettings)
        Set-ExhibitionStatus -ExhibitionPath $context.ExhibitionPath -StatusMessage 'Deploying Client'
        foreach ($line in (Copy-DirectoryMirror -Source (Join-Path $clientTempDirectory 'dist') -Destination $clientTargetDirectory)) { $tempOutput.Add($line) | Out-Null }
        Copy-Item -Path (Join-Path $clientTempDirectory '.env') -Destination (Join-Path $clientTargetDirectory '.env') -ErrorAction SilentlyContinue

        $endTime = Get-Date
        return [pscustomobject]@{
            Result          = 'Success'
            Name            = $Name
            LanguageId      = $LanguageId
            Demo            = [bool]$Demo
            Uri             = Expand-ExhibitionString -InputString ([string]$settings.ClientBaseUri) -Name $Name -LanguageId $LanguageId -ValueSets @($settings, $context.HiveSettings)
            ClientDirectory = $clientTargetDirectory
            ApiDirectory    = $apiTargetDirectory
            Start           = $startTime
            End             = $endTime
            Duration        = (New-TimeSpan -Start $startTime -End $endTime).TotalSeconds
            Output          = ($tempOutput -join [System.Environment]::NewLine)
        }
    } finally {
        if ($context) {
            Set-ExhibitionStatus -ExhibitionPath $context.ExhibitionPath -StatusMessage ''
        }
        if ($mutex) {
            if ($mutex.WaitOne(0)) {
                $mutex.ReleaseMutex() | Out-Null
            } else {
                try {
                    $mutex.ReleaseMutex() | Out-Null
                } catch {
                }
            }
            $mutex.Dispose()
        }
    }
}