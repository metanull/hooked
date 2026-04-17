function Install-Exhibition {
    [CmdletBinding(DefaultParameterSetName = 'param')]
    [OutputType([pscustomobject])]
    param(
        [Parameter(ParameterSetName = 'json', Position = 0, Mandatory = $true)]
        [string]$JsonFormData,

        [Parameter(ParameterSetName = 'jsonfile', Position = 0, Mandatory = $true)]
        [string]$JsonFilePath,

        [Parameter(ParameterSetName = 'jsonfile', Mandatory = $false)]
        [switch]$RemoveJsonFile,

        [Parameter(ParameterSetName = 'param', Position = 0, Mandatory = $true)]
        [ValidateScript({ Test-ExhibitionName -Name $_ })]
        [string]$Name,

        [Parameter(ParameterSetName = 'param', Position = 1, Mandatory = $true)]
        [ValidateScript({ Test-LanguageId -LanguageId $_ })]
        [string]$LanguageId,

        [Parameter(ParameterSetName = 'param', Position = 2, Mandatory = $true)]
        [string[]]$ApiEnvironment,

        [Parameter(ParameterSetName = 'param', Position = 3, Mandatory = $true)]
        [string[]]$ClientEnvironment,

        [Parameter(ParameterSetName = 'json', Mandatory = $false)]
        [Parameter(ParameterSetName = 'jsonfile', Mandatory = $false)]
        [Parameter(ParameterSetName = 'param', Mandatory = $false)]
        [switch]$Force
    )

    $registryRoot = Initialize-ExhibitionServerRegistry
    $exhibitionsRoot = Join-Path $registryRoot 'Exhibitions'
    if (-not (Test-Path -Path $exhibitionsRoot)) {
        New-Item -Path $exhibitionsRoot -ItemType Directory -Force | Out-Null
    }

    $ignoredKeys = @{
        ApiEnvironment = @(
            'DB_CONNECTION', 'DB_HOST', 'DB_PORT', 'DB_NAME', 'DB_USERNAME', 'DB_PASSWORD',
            'PHPCS_STANDARD', 'LOG_CHANNEL', 'BROADCAST_DRIVER', 'CACHE_DRIVER',
            'SESSION_DRIVER', 'SESSION_LIFETIME', 'QUEUE_DRIVER', 'REDIS_HOST', 'REDIS_PASSWORD',
            'REDIS_PORT', 'MAIL_DRIVER', 'MAIL_HOST', 'MAIL_PORT', 'MAIL_USERNAME',
            'MAIL_PASSWORD', 'MAIL_ENCRYPTION', 'AWS_ACCESS_KEY_ID', 'AWS_SECRET_ACCESS_KEY',
            'AWS_DEFAULT_REGION', 'AWS_BUCKET', 'PUSHER_APP_ID', 'PUSHER_APP_KEY',
            'PUSHER_APP_SECRET', 'PUSHER_APP_CLUSTER', 'MIX_PUSHER_APP_KEY', 'MIX_PUSHER_APP_CLUSTER',
            'MWNF_DB_CONNECTION', 'MWNF_DB_HOST', 'MWNF_DB_PORT', 'MWNF_DB_DATABASE',
            'MWNF_DB_USERNAME', 'MWNF_DB_PASSWORD'
        )
        ClientEnvironment = @(
            'VUE_APP_BASE_ROUTE', 'VUE_APP_EXHIBITION', 'VUE_APP_EXHIBITION_ENDPOINT', 'VUE_APP_URL_SELF'
        )
    }

    switch ($PSCmdlet.ParameterSetName) {
        'json' {
            $data = $JsonFormData | ConvertFrom-Json -ErrorAction Stop
        }
        'jsonfile' {
            $data = Get-Content -Path $JsonFilePath -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
        }
        default {
            $data = [pscustomobject]@{
                Name              = $Name
                LanguageId        = $LanguageId
                ApiEnvironment    = ($ApiEnvironment -join [System.Environment]::NewLine)
                ClientEnvironment = ($ClientEnvironment -join [System.Environment]::NewLine)
            }
        }
    }

    if (-not (Test-ExhibitionName -Name $data.Name)) {
        throw "Invalid exhibition name '$($data.Name)'."
    }
    if (-not (Test-LanguageId -LanguageId $data.LanguageId)) {
        throw "Invalid language id '$($data.LanguageId)'."
    }

    $exhibitionPath = Join-Path $exhibitionsRoot (('{0}.{1}' -f $data.Name, $data.LanguageId))
    if (Test-Path -Path $exhibitionPath) {
        if (-not $Force) {
            throw "Exhibition '$($data.Name).$($data.LanguageId)' already exists."
        }
        Remove-Item -Path $exhibitionPath -Recurse -Force -ErrorAction Stop
    }

    $apiValues = ConvertTo-EnvironmentTable -InputObject $data.ApiEnvironment
    $clientValues = ConvertTo-EnvironmentTable -InputObject $data.ClientEnvironment

    $exhibitionItem = New-Item -Path $exhibitionPath -ItemType Directory -Force -ErrorAction Stop
    Set-ItemProperty -Path $exhibitionItem.PSPath -Name 'Name' -Value $data.Name -ErrorAction Stop
    Set-ItemProperty -Path $exhibitionItem.PSPath -Name 'LanguageId' -Value $data.LanguageId -ErrorAction Stop
    Set-ItemProperty -Path $exhibitionItem.PSPath -Name 'Status' -Value '' -ErrorAction Stop

    foreach ($environmentName in @('ApiEnvironment', 'ClientEnvironment')) {
        $targetPath = Join-Path $exhibitionItem.PSPath $environmentName
        $values = if ($environmentName -eq 'ApiEnvironment') { $apiValues } else { $clientValues }
        $environmentKey = New-Item -Path $targetPath -ItemType Directory -Force -ErrorAction Stop
        foreach ($key in $values.Keys) {
            if ($key -in $ignoredKeys[$environmentName]) {
                continue
            }
            Set-ItemProperty -Path $environmentKey.PSPath -Name $key -Value $values[$key] -ErrorAction Stop
        }
    }

    if ($PSCmdlet.ParameterSetName -eq 'jsonfile' -and $RemoveJsonFile) {
        Remove-Item -Path $JsonFilePath -Force -ErrorAction Stop
    }

    return (Get-Exhibition -Name $data.Name -LanguageId $data.LanguageId)
}