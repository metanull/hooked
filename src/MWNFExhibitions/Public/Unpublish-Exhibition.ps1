function Unpublish-Exhibition {
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

    $mutex = New-Object System.Threading.Mutex($false, $script:MWNFExhibitionsConfig.PublishMutexName)
    $startTime = Get-Date
    $context = $null

    try {
        if (-not ($mutex.WaitOne($script:MWNFExhibitionsConfig.PublishMutexTimeout))) {
            throw 'Error acquiring publish mutex. The system is busy with another operation.'
        }

        $context = Get-ExhibitionDeploymentContext -Name $Name -LanguageId $LanguageId -Demo:$Demo
        $settings = $context.Settings

        $apiTargetDirectory = Expand-ExhibitionString -InputString ([string]$settings.TargetDirectoryApi) -Name $Name -LanguageId $LanguageId -ValueSets @($settings, $context.HiveSettings)
        $clientTargetDirectory = Expand-ExhibitionString -InputString ([string]$settings.TargetDirectoryClient) -Name $Name -LanguageId $LanguageId -ValueSets @($settings, $context.HiveSettings)

        Set-ExhibitionStatus -ExhibitionPath $context.ExhibitionPath -StatusMessage 'Removing API'
        if (Test-Path -Path $apiTargetDirectory) {
            Remove-Item -Path $apiTargetDirectory -Recurse -Force -ErrorAction Stop
        }

        Set-ExhibitionStatus -ExhibitionPath $context.ExhibitionPath -StatusMessage 'Removing Client'
        if (Test-Path -Path $clientTargetDirectory) {
            Remove-Item -Path $clientTargetDirectory -Recurse -Force -ErrorAction Stop
        }

        $endTime = Get-Date
        return [pscustomobject]@{
            Result          = 'Success'
            Name            = $Name
            LanguageId      = $LanguageId
            Demo            = [bool]$Demo
            ClientDirectory = $clientTargetDirectory
            ApiDirectory    = $apiTargetDirectory
            Start           = $startTime
            End             = $endTime
            Duration        = (New-TimeSpan -Start $startTime -End $endTime).TotalSeconds
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