[CmdletBinding()]
Param (
    [Parameter(Mandatory = $true, HelpMessage = "Specify the name of the configuration folder to create")]
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
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern("^[a-zA-Z0-9_-]+$")]
        [string]$FolderName
    )

    process {
        try {
            # Define paths
            $ConfigurationsRoot = Join-Path -Path $PSScriptRoot -ChildPath "Configurations"
            $TemplatesFolder = Join-Path -Path $ConfigurationsRoot -ChildPath "Templates"
            $TargetFolder = Join-Path -Path $ConfigurationsRoot -ChildPath $FolderName

            # Validate that Templates folder exists
            if (-not (Test-Path -Path $TemplatesFolder -PathType Container)) {
                throw "Templates folder not found at: $TemplatesFolder"
            }

            # Check if target folder already exists
            if (Test-Path -Path $TargetFolder) {
                Write-Warning "Configuration folder '$FolderName' already exists at: $TargetFolder"
                return $false
            }

            # Create the target folder
            if ($PSCmdlet.ShouldProcess($TargetFolder, "Create directory")) {
                Write-Verbose "Creating directory: $TargetFolder"
                $NewFolder = New-Item -Path $TargetFolder -ItemType Directory -Force
                Write-Host "Created configuration folder: $($NewFolder.FullName)" -ForegroundColor Green
            }

            # Copy template files
            $TemplateFiles = Get-ChildItem -Path $TemplatesFolder -File
            if ($TemplateFiles.Count -eq 0) {
                Write-Warning "No template files found in: $TemplatesFolder"
                return $false
            }

            if ($PSCmdlet.ShouldProcess($TargetFolder, "Copy template files")) {
                Write-Verbose "Copying $($TemplateFiles.Count) template files to: $TargetFolder"
                Copy-Item -Path "$TemplatesFolder\*" -Destination $TargetFolder -Force
                Write-Host "Successfully copied $($TemplateFiles.Count) template files" -ForegroundColor Green
            }

            return $true

        } catch {
            Write-Error "Failed to create configuration files: $($_.Exception.Message)"
            return $false
        }
    }
}

# Main execution
if (-not $PSBoundParameters.ContainsKey('WhatIf') -and -not $PSBoundParameters.ContainsKey('Confirm')) {
    $result = New-WVDConfigurationFile -FolderName $FolderName
    if ($result) {
        Write-Host "Configuration folder '$FolderName' created successfully!" -ForegroundColor Green
    } else {
        Write-Host "Failed to create configuration folder '$FolderName'" -ForegroundColor Red
        exit 1
    }
}
