Function Get-GitRepository {
    <#
        .Synopsis
            Get comprehensive information about the Git repository in the current directory.
        .Description
            Returns a PSCustomObject with: Remote, Branch, Branches (Local/Remote),
            BehindOrigin, AheadOrigin, LatestCommit, and LatestTag.
        .Example
            Get-GitRepository
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param()
    Begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"
        Write-Progress -Id 1 -PercentComplete -1 -Activity $MyInvocation.MyCommand.Name
        $OutputObject = @{}
    }
    End {
        Write-Progress -Id 1 -Completed -Activity $MyInvocation.MyCommand.Name
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function ended"
        return [PSCustomObject]$OutputObject
    }
    Process {
        try {
            $Output = (git remote get-url origin *>&1)
            if ($LASTEXITCODE -ne 0) { throw $Output }
            $OutputObject += @{ Remote = [string]$Output }

            $Output = (git branch --show-current *>&1)
            if ($LASTEXITCODE -ne 0) { throw $Output }
            $Branch = [string]$Output
            $OutputObject += @{ Branch = $Branch }

            $Output = (git branch -a --no-color *>&1)
            if ($LASTEXITCODE -ne 0) { throw $Output }
            $Output = ($Output | ForEach-Object { $_ -replace '^\s*\*?\s*' })
            $OutputObject += @{
                Branches = @{
                    Local  = [string[]]($Output | Where-Object { $_ -notmatch '^remotes/' })
                    Remote = [string[]]($Output | Where-Object { $_ -match '^remotes/' -and $_ -notmatch '(?-i:/HEAD)' })
                }
            }

            $Output = (git rev-list "origin/$Branch...$Branch" --left-right --count *>&1)
            if ($LASTEXITCODE -ne 0) {
                # Branch may not have a remote tracking counterpart
                $OutputObject += @{
                    BehindOrigin = $null
                    AheadOrigin  = $null
                }
            } else {
                $OutputObject += @{
                    BehindOrigin = ($Output -split '\s+')[0]
                    AheadOrigin  = ($Output -split '\s+')[1]
                }
            }

            $Output = (git rev-parse $Branch *>&1)
            if ($LASTEXITCODE -ne 0) { throw $Output }
            $Rev = [string]$Output
            $Output = (git show -q --format="%ci`t%cN`t%cE`t%s`t%h`t%H" $Rev *>&1)
            if ($LASTEXITCODE -ne 0) { throw $Output }
            $Output = $Output -split "`t"
            $OutputObject += @{
                LatestCommit = [ordered]@{
                    Date        = [datetime]::Parse($Output[0])
                    Author      = $Output[1]
                    Email       = $Output[2]
                    Description = $Output[3]
                    ShortCommit = $Output[4]
                    Commit      = $Output[5]
                }
            }

            $Output = (git rev-list --tags --max-count=1 *>&1)
            if ($LASTEXITCODE -ne 0) { throw $Output }
            $RevTag = [string]$Output
            if ($RevTag) {
                $Output = (git describe $RevTag *>&1)
                if ($LASTEXITCODE -ne 0) { throw $Output }
                $Tag = [string]$Output
                $Output = (git show -q --format="%ci`t%cN`t%cE`t%s`t%h`t%H" $RevTag *>&1)
                if ($LASTEXITCODE -ne 0) { throw $Output }
                $Output = $Output -split "`t"
                $OutputObject += @{
                    LatestTag = [ordered]@{
                        Tag         = $Tag
                        Date        = [datetime]::Parse($Output[0])
                        Author      = $Output[1]
                        Email       = $Output[2]
                        Description = $Output[3]
                        ShortCommit = $Output[4]
                        Commit      = $Output[5]
                    }
                }
            }
        } catch {
            throw
        }
    }
}
