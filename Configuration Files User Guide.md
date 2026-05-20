# New-WVDConfigurationFiles.ps1 - Complete User Guide

## Overview

The `New-WVDConfigurationFiles.ps1` script is a PowerShell utility designed to create customized configuration profiles for the Windows Desktop Optimization Tool (WDOT). This script creates a new configuration folder with template files that you can customize for specific Windows environments, versions, or organizational requirements.

## What This Script Does

This script performs the following actions:

1. **Creates a new configuration folder** in the `Configurations` directory
2. **Copies all template files** from the `Templates` folder to your new configuration folder
3. **Validates inputs** to ensure safe folder names and prevent conflicts
4. **Provides detailed feedback** about the creation process

## Template Files Included

When you run this script, it copies the following template configuration files to your new folder:

| File Name | Purpose |
|-----------|---------|
| `AppxPackages.json` | Controls which Windows Store apps to remove or keep |
| `Autologgers.json` | Manages Windows automatic logging services |
| `DefaultAssociationsConfiguration.xml` | Sets default file associations |
| `DefaultUserSettings.json` | Configures default user registry settings |
| `EdgeSettings.json` | Microsoft Edge browser optimization settings |
| `LanManWorkstation.json` | Network workstation service configurations |
| `PolicyRegSettings.json` | Local group policy registry settings |
| `ScheduledTasks.json` | Controls which scheduled tasks to disable |
| `Services.json` | Manages Windows services (disable/enable) |

## Prerequisites

- **PowerShell 5.1 or higher**
- **Administrator privileges** (required for the main optimization script)
- **Windows Desktop Optimization Tool** files in the correct directory structure

## Usage

### Basic Syntax

```powershell
.\New-WVDConfigurationFiles.ps1 -FolderName <ConfigurationName>
```

### Parameters

#### `-FolderName` (Required)

- **Type**: String
- **Description**: The name of the configuration folder to create
- **Restrictions**: Can only contain letters, numbers, underscores (_), and hyphens (-)
- **Examples**: "Windows11_24H2", "Server2025", "Corporate-Standard"

## Examples

### Example 1: Create a Windows 11 24H2 Configuration

```powershell
.\New-WVDConfigurationFiles.ps1 -FolderName "Windows11_24H2"
```

**Output:**

```text
Created configuration folder: D:\DevOps\Github\Windows-Desktop-Optimization-Tool\Configurations\Windows11_24H2
Successfully copied 9 template files
Configuration folder 'Windows11_24H2' created successfully!
```

### Example 2: Create a Windows Server 2025 Configuration

```powershell
.\New-WVDConfigurationFiles.ps1 -FolderName "WS2025_24H2"
```

### Example 3: Create a Corporate Standard Configuration

```powershell
.\New-WVDConfigurationFiles.ps1 -FolderName "Corporate-Standard"
```

### Example 4: Create Configuration with Verbose Output

```powershell
.\New-WVDConfigurationFiles.ps1 -FolderName "Development-VMs" -Verbose
```

**Verbose Output:**

```text
VERBOSE: Creating directory: D:\...\Configurations\Development-VMs
Created configuration folder: D:\...\Configurations\Development-VMs
VERBOSE: Copying 9 template files to: D:\...\Configurations\Development-VMs
Successfully copied 9 template files
Configuration folder 'Development-VMs' created successfully!
```

### Example 5: Test What Would Happen (WhatIf)

```powershell
.\New-WVDConfigurationFiles.ps1 -FolderName "Test-Config" -WhatIf
```

**Output:**

```text
What if: Performing the operation "Create directory" on target "D:\...\Configurations\Test-Config".
What if: Performing the operation "Copy template files" on target "D:\...\Configurations\Test-Config".
```

## Common Use Cases

### 1. Different Windows Versions

Create separate configurations for different Windows versions:

```powershell
.\New-WVDConfigurationFiles.ps1 -FolderName "Windows10_22H2"
.\New-WVDConfigurationFiles.ps1 -FolderName "Windows11_23H2"
.\New-WVDConfigurationFiles.ps1 -FolderName "Windows11_24H2"
```

### 2. Environment-Specific Configurations

Create configurations for different environments:

```powershell
.\New-WVDConfigurationFiles.ps1 -FolderName "Production"
.\New-WVDConfigurationFiles.ps1 -FolderName "Development"
.\New-WVDConfigurationFiles.ps1 -FolderName "Testing"
```

### 3. Role-Based Configurations

Create configurations for different user roles:

```powershell
.\New-WVDConfigurationFiles.ps1 -FolderName "Developer-Workstation"
.\New-WVDConfigurationFiles.ps1 -FolderName "Office-Worker"
.\New-WVDConfigurationFiles.ps1 -FolderName "Power-User"
```

## After Creating Your Configuration

Once you've created your configuration folder, follow these steps to customize it for your specific needs:

### Step 1: Customize Configuration Files with Set-WVDConfigurations.ps1

Instead of manually editing JSON files, use the included `Set-WVDConfigurations.ps1` script to interactively configure your optimization settings. This script provides a user-friendly interface to customize each configuration file.

#### Basic Usage

```powershell
.\Set-WVDConfigurations.ps1 -ConfigurationFile "<ConfigFile>" -ConfigFolderName "<YourConfigFolder>"
```

#### Supported Configuration Files

The script supports all template configuration files:

| Configuration File | Description | Items Configured |
|-------------------|-------------|------------------|
| `AppxPackages` | Windows Store Apps | Which apps to remove or keep |
| `AutoLoggers` | Auto-logging Services | Windows diagnostic logging |
| `DefaultUserSettings` | User Registry Settings | Default user preferences |
| `EdgeSettings` | Microsoft Edge Browser | Edge optimization settings |
| `LanManWorkstation` | Network Settings | SMB/File sharing optimizations |
| `PolicyRegSettings` | Local Group Policies | Security and performance policies |
| `ScheduledTasks` | Windows Tasks | Background scheduled tasks |
| `Services` | Windows Services | System services to disable/enable |

#### Interactive Configuration Examples

**Example 1: Configure Windows Services**

```powershell
.\Set-WVDConfigurations.ps1 -ConfigurationFile "Services" -ConfigFolderName "Windows11_24H2"
```

**Interactive Output:**
```text
Configuring Windows Service optimizations for 'Windows11_24H2'
Total items: 45

Windows Service: Windows Search
  Description: Provides content indexing, property caching, and search results
  Current state: Skip
  Action? [A]pply, [S]kip, [K]eep current, [Q]uit, [H]elp: A

Windows Service: Print Spooler
  Description: Loads files to memory for later printing
  Current state: Skip
  Action? [A]pply, [S]kip, [K]eep current, [Q]uit, [H]elp: S
```

**Example 2: Configure AppX Packages**

```powershell
.\Set-WVDConfigurations.ps1 -ConfigurationFile "AppxPackages" -ConfigFolderName "Production-VDI"
```

**Example 3: Configure with Backup**

```powershell
.\Set-WVDConfigurations.ps1 -ConfigurationFile "PolicyRegSettings" -ConfigFolderName "Test-Config" -CreateBackup
```

#### Advanced Usage Options

**Apply All Optimizations (Non-Interactive)**

```powershell
.\Set-WVDConfigurations.ps1 -ConfigurationFile "Services" -ConfigFolderName "Windows11_24H2" -ApplyAll
```

**Skip All Optimizations (Reset to Safe Defaults)**

```powershell
.\Set-WVDConfigurations.ps1 -ConfigurationFile "ScheduledTasks" -ConfigFolderName "Conservative-Setup" -SkipAll
```

**Create Backup Before Changes**

```powershell
.\Set-WVDConfigurations.ps1 -ConfigurationFile "DefaultUserSettings" -ConfigFolderName "Production" -CreateBackup
```

#### Interactive Commands During Configuration

When configuring each item, you have these options:

- **A** - Apply this optimization (sets `OptimizationState` to "Apply")
- **S** - Skip this optimization (sets `OptimizationState` to "Skip")
- **K** - Keep current setting (no change)
- **Q** - Quit without saving changes
- **H** - Show help with all available options

#### Complete Configuration Workflow

**Step-by-Step Process:**

1. **Start with Services (Most Critical)**:
   ```powershell
   .\Set-WVDConfigurations.ps1 -ConfigurationFile "Services" -ConfigFolderName "MyConfig" -CreateBackup
   ```

2. **Configure AppX Packages**:
   ```powershell
   .\Set-WVDConfigurations.ps1 -ConfigurationFile "AppxPackages" -ConfigFolderName "MyConfig"
   ```

3. **Set Scheduled Tasks**:
   ```powershell
   .\Set-WVDConfigurations.ps1 -ConfigurationFile "ScheduledTasks" -ConfigFolderName "MyConfig"
   ```

4. **Configure User Settings**:
   ```powershell
   .\Set-WVDConfigurations.ps1 -ConfigurationFile "DefaultUserSettings" -ConfigFolderName "MyConfig"
   ```

5. **Apply Policy Settings**:

   ```powershell
   .\Set-WVDConfigurations.ps1 -ConfigurationFile "PolicyRegSettings" -ConfigFolderName "MyConfig"
   ```

#### Batch Configuration Script

Create a PowerShell script to configure multiple files:

```powershell
# Configure-MyEnvironment.ps1
$ConfigName = "Production-Environment"
$ConfigFiles = @("Services", "AppxPackages", "ScheduledTasks", "DefaultUserSettings")

foreach ($ConfigFile in $ConfigFiles) {
    Write-Host "Configuring $ConfigFile..." -ForegroundColor Cyan
    .\Set-WVDConfigurations.ps1 -ConfigurationFile $ConfigFile -ConfigFolderName $ConfigName -CreateBackup
    Write-Host "Completed $ConfigFile configuration`n" -ForegroundColor Green
}
```

### Step 2: Understanding Optimization States

Each configuration item has an `OptimizationState` property with two possible values:

- **`Apply`**: The optimization will be applied during the main optimization process
- **`Skip`**: The optimization will be ignored (safe/conservative setting)

### Step 3: Verify Your Configuration

After configuring your files, you can verify the settings:

```powershell
# Check how many optimizations are set to Apply vs Skip
Get-Content ".\Configurations\MyConfig\Services.json" | ConvertFrom-Json | Group-Object OptimizationState | Select-Object Name, Count
```

**Example Output:**

```text
Name  Count
----  -----
Skip     28
Apply    17
```

### Step 4: Use with Main Optimization Script

Once your configuration is customized, use it with the main optimization script:

```powershell
.\Windows_Optimization.ps1 -ConfigProfile "Windows11_24H2" -Optimizations All -AcceptEULA
```

## Error Handling

The script includes comprehensive error handling:

### Common Errors and Solutions

#### Error: "Folder name can only contain letters, numbers, underscores, and hyphens"

**Solution**: Use only valid characters in your folder name.

```powershell
# ❌ Invalid
.\New-WVDConfigurationFiles.ps1 -FolderName "Windows 11 (24H2)"

# ✅ Valid
.\New-WVDConfigurationFiles.ps1 -FolderName "Windows11_24H2"
```

#### Warning: "Configuration folder already exists"

**Solution**: Choose a different name or delete the existing folder first.

```powershell
# Check existing configurations
Get-ChildItem ".\Configurations" -Directory

# Remove existing folder if needed
Remove-Item ".\Configurations\ExistingConfig" -Recurse -Force
```

#### Error: "Templates folder not found"

**Solution**: Ensure you're running the script from the correct directory and that the Templates folder exists.

## Advanced Usage

### Using with PowerShell ISE or VS Code

You can run this script directly from PowerShell ISE or VS Code:

1. Open the script file
2. Modify the `$FolderName` parameter at the top if needed
3. Run the script (F5)

### Pipeline Usage

The script supports pipeline input:

```powershell
"MyConfig" | .\New-WVDConfigurationFiles.ps1
```

### Batch Creation

Create multiple configurations at once:

```powershell
$Configs = @("Windows10_LTSC", "Windows11_Pro", "Server2022")
$Configs | ForEach-Object {
    .\New-WVDConfigurationFiles.ps1 -FolderName $_
}
```

## Integration with Main Optimization Workflow

### Complete End-to-End Workflow

This section demonstrates the complete process from creating a new configuration to applying optimizations.

#### Step 1: Create New Configuration Folder

```powershell
.\New-WVDConfigurationFiles.ps1 -FolderName "Production-VDI"
```

#### Step 2: Configure Each Template File

Configure your optimization settings using the interactive configuration script:

```powershell
# Configure Windows Services (recommended first)
.\Set-WVDConfigurations.ps1 -ConfigurationFile "Services" -ConfigFolderName "Production-VDI" -CreateBackup

# Configure AppX Packages to remove
.\Set-WVDConfigurations.ps1 -ConfigurationFile "AppxPackages" -ConfigFolderName "Production-VDI"

# Configure Scheduled Tasks to disable
.\Set-WVDConfigurations.ps1 -ConfigurationFile "ScheduledTasks" -ConfigFolderName "Production-VDI"

# Configure Default User Settings
.\Set-WVDConfigurations.ps1 -ConfigurationFile "DefaultUserSettings" -ConfigFolderName "Production-VDI"

# Configure Group Policy Settings
.\Set-WVDConfigurations.ps1 -ConfigurationFile "PolicyRegSettings" -ConfigFolderName "Production-VDI"
```

#### Step 3: Review Configuration Summary

Verify your configuration settings:

```powershell
# Check Services configuration
$ServicesConfig = Get-Content ".\Configurations\Production-VDI\Services.json" | ConvertFrom-Json
$ServicesConfig | Group-Object OptimizationState | Select-Object Name, Count

# Check AppX Packages configuration  
$AppxConfig = Get-Content ".\Configurations\Production-VDI\AppxPackages.json" | ConvertFrom-Json
$AppxConfig | Group-Object OptimizationState | Select-Object Name, Count
```

#### Step 4: Apply Optimizations

Run the main optimization script with your custom configuration:

```powershell
# Apply all optimizations with your custom profile
.\Windows_Optimization.ps1 -ConfigProfile "Production-VDI" -Optimizations All -AcceptEULA

# Or apply specific optimization categories
.\Windows_Optimization.ps1 -ConfigProfile "Production-VDI" -Optimizations @("Services", "AppxPackages", "ScheduledTasks") -AcceptEULA
```

### Environment-Specific Workflow Examples

#### Development Environment Setup

```powershell
# 1. Create development configuration
.\New-WVDConfigurationFiles.ps1 -FolderName "Development-Workstation"

# 2. Apply conservative settings (skip most optimizations for stability)
.\Set-WVDConfigurations.ps1 -ConfigurationFile "Services" -ConfigFolderName "Development-Workstation" -SkipAll
.\Set-WVDConfigurations.ps1 -ConfigurationFile "AppxPackages" -ConfigFolderName "Development-Workstation" -SkipAll

# 3. Manually configure only critical optimizations
.\Set-WVDConfigurations.ps1 -ConfigurationFile "ScheduledTasks" -ConfigFolderName "Development-Workstation"

# 4. Apply optimizations
.\Windows_Optimization.ps1 -ConfigProfile "Development-Workstation" -Optimizations All -AcceptEULA
```

#### Production VDI Environment Setup

```powershell
# 1. Create production VDI configuration
.\New-WVDConfigurationFiles.ps1 -FolderName "Production-VDI-2025"

# 2. Apply aggressive optimizations for VDI performance
.\Set-WVDConfigurations.ps1 -ConfigurationFile "Services" -ConfigFolderName "Production-VDI-2025" -ApplyAll
.\Set-WVDConfigurations.ps1 -ConfigurationFile "AppxPackages" -ConfigFolderName "Production-VDI-2025" -ApplyAll
.\Set-WVDConfigurations.ps1 -ConfigurationFile "ScheduledTasks" -ConfigFolderName "Production-VDI-2025" -ApplyAll

# 3. Review and adjust specific settings interactively
.\Set-WVDConfigurations.ps1 -ConfigurationFile "DefaultUserSettings" -ConfigFolderName "Production-VDI-2025"

# 4. Apply optimizations
.\Windows_Optimization.ps1 -ConfigProfile "Production-VDI-2025" -Optimizations All -AcceptEULA
```

### Configuration Testing and Validation

#### Test Configuration Before Production

```powershell
# 1. Create test configuration based on production
.\New-WVDConfigurationFiles.ps1 -FolderName "Test-Production-VDI"

# 2. Copy settings from existing configuration
Copy-Item ".\Configurations\Production-VDI\*" ".\Configurations\Test-Production-VDI\" -Force

# 3. Test on non-production system
.\Windows_Optimization.ps1 -ConfigProfile "Test-Production-VDI" -Optimizations All -AcceptEULA

# 4. Validate results and adjust if needed
.\Set-WVDConfigurations.ps1 -ConfigurationFile "Services" -ConfigFolderName "Test-Production-VDI"
```

## Best Practices

### Naming Conventions

- Use descriptive names that indicate the purpose or target environment
- Include version numbers when applicable
- Use consistent naming patterns across your organization

**Good Examples:**

- `Windows11_24H2_Corporate`
- `AVD_Production_v2`
- `Dev_Workstation_Standard`

**Avoid:**

- Generic names like `Config1`, `Test`, `New`
- Special characters or spaces
- Extremely long names

### Configuration Management

- **Version Control**: Consider storing your custom configurations in version control
- **Documentation**: Document the purpose and specific customizations of each configuration
- **Testing**: Always test configurations in a non-production environment first
- **Backup**: Keep backups of working configurations before making changes

## Troubleshooting

### Script Won't Run

1. Check PowerShell execution policy:

   ```powershell
   Get-ExecutionPolicy
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

2. Ensure you're in the correct directory:

   ```powershell
   Get-Location
   Set-Location "D:\DevOps\Github\Windows-Desktop-Optimization-Tool"
   ```

### Verbose Troubleshooting

Run with verbose output to see detailed information:

```powershell
.\New-WVDConfigurationFiles.ps1 -FolderName "Debug-Test" -Verbose
```

### Validate File Structure

Check that all required files and folders exist:

```powershell
# Check main directory structure
Get-ChildItem -Path "." -Directory | Select-Object Name

# Check Templates folder
Get-ChildItem -Path ".\Configurations\Templates" | Select-Object Name, Length
```

## Support and Maintenance

This script is part of the Windows Desktop Optimization Tool project. For:

- **Bug reports**: Check the project's issue tracker
- **Feature requests**: Submit through the project's standard channels
- **Documentation updates**: Contribute to the project documentation

## Version History

- **v2.0**: Enhanced error handling, validation, and PowerShell best practices
- **v1.0**: Initial release with basic functionality

---

*Last updated: October 30, 2025*  
*Author: Tim Muessig*  
*Project: Windows Desktop Optimization Tool*
