function Get-ExhibitionServerRegistryRoot {
    [CmdletBinding()]
    [OutputType([string])]
    param()

    return (Join-Path $script:MWNFExhibitionsConfig.RegistryHive 'ExhibitionServer')
}

function Get-RegistryValueSet {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $excluded = 'PSPath', 'PSParentPath', 'PSChildName', 'PSProvider', 'PSDrive'
    $values = [ordered]@{}

    if (-not (Test-Path -Path $Path)) {
        return [pscustomobject]$values
    }

    $item = Get-ItemProperty -Path $Path -ErrorAction Stop
    foreach ($property in $item.PSObject.Properties) {
        if ($property.Name -notin $excluded) {
            $values[$property.Name] = $property.Value
        }
    }

    return [pscustomobject]$values
}

function Merge-RegistryValueSet {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$Base,

        [Parameter(Mandatory = $true)]
        [pscustomobject]$Override
    )

    $merged = [ordered]@{}
    foreach ($valueSet in @($Base, $Override)) {
        foreach ($property in $valueSet.PSObject.Properties) {
            $merged[$property.Name] = $property.Value
        }
    }

    return [pscustomobject]$merged
}

function Initialize-ExhibitionServerRegistry {
    [CmdletBinding()]
    [OutputType([string])]
    param()

    $registryRoot = Get-ExhibitionServerRegistryRoot
    if (Test-Path -Path $registryRoot) {
        return $registryRoot
    }

    $templateFile = Resolve-Path -Path $script:MWNFExhibitionsConfig.TemplateFile -ErrorAction Stop | Select-Object -ExpandProperty Path
    $reg = Get-Command reg.exe -ErrorAction Stop
    $process = Start-Process -FilePath $reg.Source -ArgumentList @('import', $templateFile) -NoNewWindow -Wait -PassThru

    if ($process.ExitCode -ne 0) {
        throw "Unable to initialize registry key '$registryRoot' from '$templateFile'."
    }
    if (-not (Test-Path -Path $registryRoot)) {
        throw "Registry key '$registryRoot' was not created by '$templateFile'."
    }

    return $registryRoot
}

function ConvertTo-EnvironmentTable {
    [CmdletBinding()]
    [OutputType([System.Collections.Specialized.OrderedDictionary])]
    param(
        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [object]$InputObject
    )

    $table = [System.Collections.Specialized.OrderedDictionary]::new()

    if ($null -eq $InputObject) {
        return $table
    }

    if ($InputObject -is [string]) {
        $lines = $InputObject -split "`r?`n"
        $parsed = ConvertFrom-DotEnv -DotEnv $lines
        foreach ($key in $parsed.Keys) {
            $table[$key] = $parsed[$key]
        }
        return $table
    }

    if ($InputObject -is [string[]]) {
        $parsed = ConvertFrom-DotEnv -DotEnv $InputObject
        foreach ($key in $parsed.Keys) {
            $table[$key] = $parsed[$key]
        }
        return $table
    }

    if ($InputObject -is [System.Collections.IDictionary]) {
        foreach ($key in $InputObject.Keys) {
            $table[$key] = $InputObject[$key]
        }
        return $table
    }

    if ($InputObject -is [pscustomobject]) {
        foreach ($property in $InputObject.PSObject.Properties) {
            $table[$property.Name] = $property.Value
        }
        return $table
    }

    throw "Unsupported environment input type '$($InputObject.GetType().FullName)'."
}

function Expand-ExhibitionString {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$InputString,

        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [string]$LanguageId,

        [Parameter(Mandatory = $true)]
        [object[]]$ValueSets
    )

    $topLevel = [pscustomobject]@{
        Name       = $Name
        LanguageId = $LanguageId
    }

    return (Expand-String -InputString $InputString -ValueSets (@($topLevel) + $ValueSets))
}

function ConvertTo-ExhibitionDotEnvTable {
    [CmdletBinding()]
    [OutputType([System.Collections.Specialized.OrderedDictionary])]
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$TemplateValues,

        [Parameter(Mandatory = $true)]
        [pscustomobject]$Values,

        [Parameter(Mandatory = $true)]
        [pscustomobject]$Settings,

        [Parameter(Mandatory = $true)]
        [pscustomobject]$HiveSettings,

        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [string]$LanguageId
    )

    $table = [System.Collections.Specialized.OrderedDictionary]::new()
    foreach ($property in $TemplateValues.PSObject.Properties) {
        $table[$property.Name] = $property.Value
    }
    foreach ($property in $Values.PSObject.Properties) {
        $table[$property.Name] = $property.Value
    }
    foreach ($key in @($table.Keys)) {
        $table[$key] = Expand-ExhibitionString -InputString ([string]$table[$key]) -Name $Name -LanguageId $LanguageId -ValueSets @($Settings, $HiveSettings)
    }

    return $table
}

function Sync-RepositoryWorkingCopy {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Directory,

        [Parameter(Mandatory = $true)]
        [Uri]$Repository,

        [Parameter(Mandatory = $true)]
        [string]$Branch
    )

    $parentDirectory = Split-Path -Path $Directory -Parent
    if (-not (Test-Path -Path $parentDirectory)) {
        New-Item -Path $parentDirectory -ItemType Directory -Force | Out-Null
    }

    if (-not (Test-Path -Path $Directory)) {
        Push-Location $parentDirectory
        try {
            Import-GitRepository -Repository $Repository -Name (Split-Path -Path $Directory -Leaf)
        } finally {
            Pop-Location
        }
    }

    Push-Location $Directory
    try {
        Set-GitCurrentBranch -Branch $Branch
        Sync-GitRepository
        Reset-GitRepository
        Update-GitCurrentBranch
    } finally {
        Pop-Location
    }
}

function Invoke-ExternalCommand {
    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $false)]
        [string[]]$ArgumentList = @(),

        [Parameter(Mandatory = $false)]
        [string]$WorkingDirectory,

        [Parameter(Mandatory = $false)]
        [int[]]$SuccessExitCodes = @(0)
    )

    $previousLocation = Get-Location
    try {
        if ($WorkingDirectory) {
            Set-Location -Path $WorkingDirectory -ErrorAction Stop
        }

        $output = & $FilePath @ArgumentList 2>&1
        $exitCode = $LASTEXITCODE
        if ($null -eq $exitCode) {
            $exitCode = 0
        }
        if ($exitCode -notin $SuccessExitCodes) {
            $commandText = ($ArgumentList | ForEach-Object { $_ }) -join ' '
            $outputText = ($output | ForEach-Object { [string]$_ }) -join [System.Environment]::NewLine
            throw "Command failed: $FilePath $commandText`n$outputText"
        }

        return [string[]]($output | ForEach-Object { [string]$_ })
    } finally {
        if ($WorkingDirectory) {
            Set-Location -Path $previousLocation
        }
    }
}

function Copy-DirectoryMirror {
    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Source,

        [Parameter(Mandatory = $true)]
        [string]$Destination
    )

    if (-not (Test-Path -Path $Destination)) {
        New-Item -Path $Destination -ItemType Directory -Force | Out-Null
    }

    return (Invoke-ExternalCommand -FilePath 'robocopy' -ArgumentList @($Source, $Destination, '/MIR', '/NFL', '/NDL', '/XD', '.git') -SuccessExitCodes @(0, 1, 2, 3, 4, 5, 6, 7))
}

function Set-ExhibitionStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ExhibitionPath,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$StatusMessage
    )

    if (-not (Test-Path -Path $ExhibitionPath)) {
        return
    }

    try {
        Set-ItemProperty -Path $ExhibitionPath -Name 'Status' -Value $StatusMessage -ErrorAction Stop
    } catch {
        Write-Warning $_.Exception.Message
    }
}

function Write-LaravelConfigEnvironmentOverrides {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Directory,

        [Parameter(Mandatory = $true)]
        [System.Collections.Specialized.OrderedDictionary]$Environment
    )

    Get-ChildItem -Path (Join-Path $Directory 'config') -Filter '*.php' -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
        $configFile = $_.FullName
        $rewritten = foreach ($line in (Get-Content -Path $configFile)) {
            $processed = $false
            if ($line -match '^(.*=>\s*)(env\(.*?\)),?\s*$') {
                $head = $Matches[1]
                $tail = $Matches[2]
                if ($tail -match "^env\(\s*'([^']+)'(.*?)?\)\s*$") {
                    $key = $Matches[1]
                    if ($Environment.Contains($key)) {
                        $processed = $true
                        $value = [string]$Environment[$key]
                        switch -Regex ($value) {
                            '^true$' { "$head TRUE,"; break }
                            '^false$' { "$head FALSE,"; break }
                            '^null$' { "$head NULL,"; break }
                            '^\d+$' { "$head $value,"; break }
                            default { "$head '$($value -replace '''', '\''')',"; break }
                        }
                    }
                }
            }
            if (-not $processed) {
                $line
            }
        }
        Set-Content -Path $configFile -Value $rewritten -Force
    }
}

function Get-ExhibitionDeploymentContext {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [string]$LanguageId,

        [Parameter(Mandatory = $false)]
        [switch]$Demo
    )

    $server = Import-ExhibitionServerConfiguration
    $root = $server.Path
    $hiveSettings = Get-RegistryValueSet -Path (Join-Path $script:MWNFExhibitionsConfig.RegistryHive 'Settings')
    $settings = Get-RegistryValueSet -Path (Join-Path $root 'Settings')
    if ($Demo) {
        $demoSettings = Get-RegistryValueSet -Path (Join-Path $root 'SettingsDemo')
        $settings = Merge-RegistryValueSet -Base $settings -Override $demoSettings
    }

    $exhibitionsRoot = Join-Path $root 'Exhibitions'
    $exhibitionPath = Join-Path $exhibitionsRoot (('{0}.{1}' -f $Name, $LanguageId))
    if (-not (Test-Path -Path $exhibitionPath)) {
        throw "Exhibition '$Name.$LanguageId' does not exist in '$exhibitionsRoot'."
    }

    return [pscustomobject]@{
        Root              = $root
        HiveSettings      = $hiveSettings
        Settings          = $settings
        ApiTemplate       = Get-RegistryValueSet -Path (Join-Path $root 'Settings\ApiEnvironment')
        ClientTemplate    = Get-RegistryValueSet -Path (Join-Path $root 'Settings\ClientEnvironment')
        ExhibitionPath    = $exhibitionPath
        ApiEnvironment    = Get-RegistryValueSet -Path (Join-Path $exhibitionPath 'ApiEnvironment')
        ClientEnvironment = Get-RegistryValueSet -Path (Join-Path $exhibitionPath 'ClientEnvironment')
    }
}