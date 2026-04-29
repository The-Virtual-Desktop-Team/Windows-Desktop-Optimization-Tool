#Requires -Version 5.1
[CmdletBinding()]
Param (
    [Parameter(Mandatory, HelpMessage = 'Specify the name of the configuration folder to create')]
    [ValidateNotNullOrEmpty()]
    [ValidatePattern("^[a-zA-Z0-9_-]+$")]
    [string]$FolderName
)

<#
.SYNOPSIS
    Creates a new WVD configuration folder with template files.

.DESCRIPTION
    This function creates a new folder in the Configurations directory and copies
    all template configuration files to the new folder.

.PARAMETER FolderName
    The name of the configuration folder to create. Must contain only letters,
    numbers, underscores, and hyphens.

.EXAMPLE
    .\New-WVDConfigurationFiles.ps1 -FolderName <your config name>
    Ex. .\New-WVDConfigurationFiles.ps1 -FolderName "W11_24H2"
    Ex. .\New-WVDConfigurationFiles.ps1 -FolderName "WS25_24H2"
    Creates a new folder called <your config name> with all template files.

.NOTES
    Author: Tim Muessig
    Version: 2.0
    Requires: PowerShell 5.1 or higher
#>
Function New-WVDConfigurationFile {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([System.Boolean])]
    Param (
        [Parameter(Mandatory,ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern("^[a-zA-Z0-9_-]+$")]
        [string]$FolderName
    )
    Begin {
        $HT = @{ ErrorAction = 'Stop' }
        $sHT = @{ ErrorAction = 'SilentlyContinue' }
    }
    Process {
        try {
            # Define paths
            $ConfigurationsRoot = Join-Path -Path $PSScriptRoot -ChildPath 'Configurations'
            $TemplatesFolder = Join-Path -Path $ConfigurationsRoot -ChildPath 'Templates'
            $TargetFolder = Join-Path -Path $ConfigurationsRoot -ChildPath $FolderName

            # Validate that Templates folder exists
            if (-not (Test-Path -Path $TemplatesFolder -PathType Container)) {
                throw "Templates folder not found at: $TemplatesFolder"
            }

            # Check if target folder already exists
            if (Test-Path -Path $TargetFolder -PathType Container) {
                Write-Warning "Configuration folder '$FolderName' already exists at: $TargetFolder"
                return $false
            }

            # Create the target folder
            if ($PSCmdlet.ShouldProcess($TargetFolder, 'Create directory')) {
                Write-Verbose -Message "Creating directory: $TargetFolder"
                try {
                 $NewFolder = New-Item -Path $TargetFolder -ItemType Directory -Force @HT
                 Write-Host -Object "Created configuration folder: $($NewFolder.FullName)" -ForegroundColor Green
                } catch {
                 Write-Warning -Message "Failed to create $($TargetFolder) because $($_.Exception.Message)"
                 return $false
                }
            }

            # Copy template files
            $TemplateFiles = Get-ChildItem -Path $TemplatesFolder -File @sHT
            if ($TemplateFiles.Count -eq 0) {
                Write-Warning -Message "No template files found in: $TemplatesFolder"
                return $false
            }

            if ($PSCmdlet.ShouldProcess($TargetFolder, 'Copy template files')) {
                Write-Verbose -Message "Copying $($TemplateFiles.Count) template files to: $TargetFolder"
                try {
                 Copy-Item -Path "$TemplatesFolder\*" -Destination $TargetFolder -Force @HT
                 Write-Host -Object "Successfully copied $($TemplateFiles.Count) template files" -ForegroundColor Green
                } catch {
                 Write-Warning -Message "Failed to copy files to $($TargetFolder) because $($_.Exception.Message)"
                 return $false
                }
            }

            return $true

        } catch {
            Write-Error -Message "Failed to create configuration files: $($_.Exception.Message)"
            return $false
        }
    }
    End {}
}

# Main execution
if (-not $PSBoundParameters.ContainsKey('WhatIf') -and -not $PSBoundParameters.ContainsKey('Confirm')) {
    $result = New-WVDConfigurationFile -FolderName $FolderName
    if ($result) {
        Write-Host -Object "Configuration folder '$FolderName' created successfully!" -ForegroundColor Green
    } else {
        Write-Host -Object "Failed to create configuration folder '$FolderName'" -ForegroundColor Red
        exit 1
    }
}
