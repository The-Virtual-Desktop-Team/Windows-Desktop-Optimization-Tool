[CmdletBinding()]
Param (
    [Parameter(Mandatory = $true, HelpMessage = "Specify the configuration file name (with or without .json extension)")]
    [ValidateNotNullOrEmpty()]
    [string]$ConfigurationFile,

    [Parameter(Mandatory = $true, HelpMessage = "Specify the configuration folder name")]
    [ValidateNotNullOrEmpty()]
    [ValidatePattern("^[a-zA-Z0-9_-]+$")]
    [string]$ConfigFolderName,

    [Parameter(HelpMessage = "Apply all optimizations without prompting")]
    [switch]$ApplyAll,

    [Parameter(HelpMessage = "Skip all optimizations without prompting")]
    [switch]$SkipAll,

    [Parameter(HelpMessage = "Create backup of original file before modifications")]
    [switch]$CreateBackup
)

<#
.SYNOPSIS
    Configures WVD optimization settings for a specific configuration file.

.DESCRIPTION
    This function allows interactive configuration of WVD optimization settings
    by reading a JSON configuration file and prompting the user to enable or
    disable each optimization item. Supports both flat array structures (like
    Services.json, AppxPackages.json) and nested structures (like LanManWorkstation.json).

.PARAMETER ConfigurationFile
    The name of the configuration file to modify (with or without .json extension).
    Valid files: AppxPackages, AutoLoggers, DefaultUserSettings, EdgeSettings,
    LanManWorkstation, PolicyRegSettings, ScheduledTasks, Services.

.PARAMETER ConfigFolderName
    The name of the configuration folder containing the files to modify.

.PARAMETER ApplyAll
    If specified, applies all optimizations without prompting the user.

.PARAMETER SkipAll
    If specified, skips all optimizations without prompting the user.

.PARAMETER CreateBackup
    If specified, creates a backup of the original file before making changes.

.EXAMPLE
    .\Set-WVDConfigurations.ps1 -ConfigurationFile "AppxPackages" -ConfigFolderName "Production"
    Interactively configure AppxPackages optimizations for the Production folder.

.EXAMPLE
    .\Set-WVDConfigurations.ps1 -ConfigurationFile "Services.json" -ConfigFolderName "Test1" -ApplyAll
    Apply all Services optimizations for the Test1 folder without prompting.

.NOTES
    Author: Your Name
    Version: 2.0
    Requires: PowerShell 5.1 or higher
#>
Function Set-WVDConfiguration
{
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([System.Boolean])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ConfigurationFile,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern("^[a-zA-Z0-9_-]+$")]
        [string]$ConfigFolderName,

        [Parameter()]
        [switch]$ApplyAll,

        [Parameter()]
        [switch]$SkipAll,

        [Parameter()]
        [switch]$CreateBackup
    )

    begin
    {
        # Define configuration file property mappings
        $ConfigMappings = @{
            'AppxPackages'        = @{ PropName = 'AppxPackage'; Description = 'Windows App Package'; IsNested = $false }
            'AutoLoggers'         = @{ PropName = 'KeyName'; Description = 'Auto Logger'; IsNested = $false }
            'DefaultUserSettings' = @{ PropName = 'KeyName'; Description = 'User Setting'; IsNested = $false }
            'EdgeSettings'        = @{ PropName = 'RegItemValueName'; Description = 'Edge Setting'; IsNested = $false }
            'LanManWorkstation'   = @{ PropName = 'Name'; Description = 'Network Setting'; IsNested = $true; NestedProperty = 'Keys' }
            'PolicyRegSettings'   = @{ PropName = 'RegItemValueName'; Description = 'Policy Setting'; IsNested = $false }
            'ScheduledTasks'      = @{ PropName = 'ScheduledTask'; Description = 'Scheduled Task'; IsNested = $false }
            'Services'            = @{ PropName = 'Name'; Description = 'Windows Service'; IsNested = $false }
        }

        # Validate conflicting parameters
        if ($ApplyAll -and $SkipAll)
        {
            throw "Cannot specify both -ApplyAll and -SkipAll parameters simultaneously."
        }
    }

    process
    {
        try
        {
            # Normalize configuration file name
            $ConfigFileBaseName = [System.IO.Path]::GetFileNameWithoutExtension($ConfigurationFile)
            if (-not $ConfigurationFile.EndsWith('.json'))
            {
                $ConfigurationFile = "$ConfigFileBaseName.json"
            }

            # Validate configuration file type (case-insensitive lookup)
            $ConfigMapping = $null
            foreach ($Key in $ConfigMappings.Keys)
            {
                if ($Key -eq $ConfigFileBaseName -or $Key.ToLower() -eq $ConfigFileBaseName.ToLower())
                {
                    $ConfigMapping = $ConfigMappings[$Key]
                    break
                }
            }

            if (-not $ConfigMapping)
            {
                $ValidFiles = $ConfigMappings.Keys -join ', '
                throw "Invalid configuration file '$ConfigFileBaseName'. Valid files are: $ValidFiles"
            }

            # Build target file path
            $ConfigurationsRoot = Join-Path -Path $PSScriptRoot -ChildPath "Configurations"
            $ConfigFolder = Join-Path -Path $ConfigurationsRoot -ChildPath $ConfigFolderName
            $TargetFile = Join-Path -Path $ConfigFolder -ChildPath $ConfigurationFile

            # Validate paths exist
            if (-not (Test-Path -Path $ConfigFolder -PathType Container))
            {
                throw "Configuration folder not found: $ConfigFolder"
            }

            if (-not (Test-Path -Path $TargetFile -PathType Leaf))
            {
                throw "Configuration file not found: $TargetFile"
            }

            # Create backup if requested
            if ($CreateBackup)
            {
                $BackupFile = "$TargetFile.backup.$(Get-Date -Format 'yyyyMMdd-HHmmss')"
                Write-Verbose "Creating backup: $BackupFile"
                Copy-Item -Path $TargetFile -Destination $BackupFile -Force
                Write-Host "Backup created: $BackupFile" -ForegroundColor Green
            }

            # Read and parse configuration file
            Write-Verbose "Reading configuration file: $TargetFile"
            $Content = Get-Content -Path $TargetFile -Raw | ConvertFrom-Json

            if (-not $Content -or $Content.Count -eq 0)
            {
                Write-Warning "Configuration file is empty or invalid: $TargetFile"
                return $false
            }

            $PropName = $ConfigMapping.PropName
            $Description = $ConfigMapping.Description
            $IsNested = $ConfigMapping.IsNested
            $NestedProperty = $ConfigMapping.NestedProperty
            $ModifiedCount = 0

            # Get the actual configuration items based on structure
            if ($IsNested -and $NestedProperty)
            {
                # Handle nested structure (like LanManWorkstation)
                $ConfigItems = @()
                foreach ($Section in $Content)
                {
                    if ($Section.$NestedProperty)
                    {
                        $ConfigItems += $Section.$NestedProperty
                    }
                }
            }
            else
            {
                # Handle flat structure (like Services, AppxPackages, etc.)
                $ConfigItems = $Content
            }

            $TotalCount = $ConfigItems.Count

            Write-Host "`nConfiguring $Description optimizations for '$ConfigFolderName'" -ForegroundColor Cyan
            Write-Host "Total items: $TotalCount" -ForegroundColor Yellow

            if ($TotalCount -eq 0)
            {
                Write-Warning "No configuration items found in file: $TargetFile"
                return $false
            }

            # Process each configuration item
            foreach ($Config in $ConfigItems)
            {
                $Name = if ($PropName) { $Config.$PropName } else { "Unknown" }
                $CurrentState = $Config.OptimizationState

                if (-not $Name)
                {
                    Write-Warning "Skipping item with missing name property '$PropName'"
                    continue
                }

                $NewState = $CurrentState

                if ($ApplyAll)
                {
                    $NewState = 'Apply'
                }
                elseif ($SkipAll)
                {
                    $NewState = 'Skip'
                }
                else
                {
                    # Interactive mode
                    $ItemDescription = if ($Config.Description) { " - $($Config.Description)" } else { "" }

                    # For nested items, show additional context
                    $ContextInfo = ""
                    if ($IsNested)
                    {
                        if ($Config.PropertyValue)
                        {
                            $ContextInfo = " (Value: $($Config.PropertyValue))"
                        }
                        if ($Config.PropertyType)
                        {
                            $ContextInfo += " [Type: $($Config.PropertyType)]"
                        }
                    }

                    Write-Host "`n$Description`: " -NoNewline -ForegroundColor White
                    Write-Host "$Name" -ForegroundColor Yellow
                    if ($ContextInfo)
                    {
                        Write-Host "  Details:$ContextInfo" -ForegroundColor Cyan
                    }
                    if ($ItemDescription)
                    {
                        Write-Host "  Description:$ItemDescription" -ForegroundColor Gray
                    }
                    Write-Host "  Current state: " -NoNewline -ForegroundColor Gray
                    $StateColor = if ($CurrentState -eq 'Apply') { 'Green' } else { 'Red' }
                    Write-Host "$CurrentState" -ForegroundColor $StateColor

                    do
                    {
                        $Response = Read-Host "  Action? [A]pply, [S]kip, [K]eep current, [Q]uit, [H]elp"
                        switch ($Response.ToUpper())
                        {
                            'A' { $NewState = 'Apply'; break }
                            'S' { $NewState = 'Skip'; break }
                            'K' { $NewState = $CurrentState; break }
                            'Q'
                            {
                                Write-Host "Configuration cancelled by user." -ForegroundColor Yellow
                                return $false
                            }
                            'H'
                            {
                                Write-Host "`n  Available options:" -ForegroundColor Cyan
                                Write-Host "    A - Apply this optimization" -ForegroundColor Green
                                Write-Host "    S - Skip this optimization" -ForegroundColor Red
                                Write-Host "    K - Keep current setting ($CurrentState)" -ForegroundColor Gray
                                Write-Host "    Q - Quit without saving changes" -ForegroundColor Yellow
                                Write-Host "    H - Show this help" -ForegroundColor Cyan
                                continue
                            }
                            default
                            {
                                Write-Host "  Invalid option. Press 'H' for help." -ForegroundColor Red
                                continue
                            }
                        }
                        break
                    } while ($true)
                }

                # Update the configuration if changed
                if ($NewState -ne $CurrentState)
                {
                    $Config.OptimizationState = $NewState
                    $ModifiedCount++
                    Write-Verbose "Changed '$Name' from '$CurrentState' to '$NewState'"
                }
            }

            # Save changes if any modifications were made
            if ($PSCmdlet.ShouldProcess($TargetFile, "Save configuration changes"))
            {
                if ($ModifiedCount -gt 0)
                {
                    Write-Verbose "Saving $ModifiedCount changes to: $TargetFile"
                    $Content | ConvertTo-Json -Depth 10 | Set-Content -Path $TargetFile -Encoding UTF8
                    Write-Host "`nConfiguration saved successfully!" -ForegroundColor Green
                    Write-Host "Modified $ModifiedCount out of $TotalCount items." -ForegroundColor Yellow
                }
                else
                {
                    Write-Host "`nNo changes were made." -ForegroundColor Yellow
                }
            }

            return $true

        }
        catch
        {
            Write-Error "Failed to configure WVD settings: $($_.Exception.Message)"
            return $false
        }
    }
}

# Main execution
if (-not $PSBoundParameters.ContainsKey('WhatIf') -and -not $PSBoundParameters.ContainsKey('Confirm'))
{
    $params = @{
        ConfigurationFile = $ConfigurationFile
        ConfigFolderName  = $ConfigFolderName
    }

    if ($ApplyAll) { $params.ApplyAll = $true }
    if ($SkipAll) { $params.SkipAll = $true }
    if ($CreateBackup) { $params.CreateBackup = $true }

    $result = Set-WVDConfiguration @params

    if ($result)
    {
        Write-Host "`nConfiguration completed successfully!" -ForegroundColor Green
    }
    else
    {
        Write-Host "`nConfiguration failed or was cancelled." -ForegroundColor Red
        exit 1
    }
}
