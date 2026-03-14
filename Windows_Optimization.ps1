#Requires -RunAsAdministrator
#Requires -PSEdition Desktop

<#####################################################################################################################################

    This Sample Code is provided for the purpose of illustration only and is not intended to be used in a production environment.
    THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED,
    INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.  We grant
    You a nonexclusive, royalty-free right to use and modify the Sample Code and to reproduce and distribute the object code form
    of the Sample Code, provided that You agree: (i) to not use Our name, logo, or trademarks to market Your software product in
    which the Sample Code is embedded; (ii) to include a valid copyright notice on Your software product in which the Sample Code
    is embedded; and (iii) to indemnify, hold harmless, and defend Us and Our suppliers from and against any claims or lawsuits,
    including attorneys’ fees, that arise or result from the use or distribution of the Sample Code.

    Microsoft provides programming examples for illustration only, without warranty either expressed or
    implied, including, but not limited to, the implied warranties of merchantability and/or fitness
    for a particular purpose.

    This sample assumes that you are familiar with the programming language being demonstrated and the
    tools used to create and debug procedures. Microsoft support professionals can help explain the
    functionality of a particular procedure, but they will not modify these examples to provide added
    functionality or construct procedures to meet your specific needs. if you have limited programming
    experience, you may want to contact a Microsoft Certified Partner or the Microsoft fee-based consulting
    line at (800) 936-5200.

    For more information about Microsoft Certified Partners, please visit the following Microsoft Web site:
    https://partner.microsoft.com/global/30000104

######################################################################################################################################>

<#
- TITLE:          Microsoft Windows Virtual Desktop Optimization Script
- AUTHORED BY:    Robert M. Smith and Tim Muessig (Microsoft)
- AUTHORED DATE:  8/12/2025
- CONTRIBUTORS:
- LAST UPDATED:
- PURPOSE:        To automatically apply many optimization settings to and Windows device; VDI, AVD, standalone machine

- Important:      Every setting in this script and input files are possible optimizations only,
                  and NOT recommendations or requirements. Please evaluate every setting for applicability
                  to your specific environment. These scripts have been tested on Hyper-V VMs, as well as Azure VMs...
                  including Windows 11 23H2.
                  Please test thoroughly in your environment before implementation

- DEPENDENCIES    1. On the target machine, run PowerShell elevated (as administrator)
                  2. Within PowerShell, set exectuion policy to enable the running of scripts.
                     Ex. Set-ExecutionPolicy -ExecutionPolicy RemoteSigned
                  5. This PowerShell script
                  6. The text input files containing all the apps, services, traces, etc. that you...
                     may be interested in disabling. Please review these input files to customize...
                     to your environment/requirements

- REFERENCES:
https://social.technet.microsoft.com/wiki/contents/articles/7703.powershell-running-executables.aspx
https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.management/remove-item?view=powershell-6
https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.management/set-service?view=powershell-6
https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.management/remove-item?view=powershell-6
https://msdn.microsoft.com/en-us/library/cc422938.aspx
#>

[Cmdletbinding(DefaultParameterSetName = 'ByConfigProfile')]
Param (
    # Parameter help description
    [Parameter(ParameterSetName = 'ByWindowsVersion', DontShow = $true)]
    [ArgumentCompleter( { Get-ChildItem -Path $PSScriptRoot\Configurations -Directory | Select-Object -ExpandProperty Name } )]
    [System.String]$WindowsVersion = (Get-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\').ReleaseId,

    [Parameter(Mandatory = $true, ParameterSetName = 'ByConfigProfile')]
    [ArgumentCompleter( { Get-ChildItem -Path $PSScriptRoot\Configurations -Directory | Select-Object -ExpandProperty Name } )]
    [string]$ConfigProfile,
    [ValidateSet('All', 'WindowsMediaPlayer', 'AppxPackages', 'ScheduledTasks', 'DefaultUserSettings', 'LocalPolicy', 'Autologgers', 'Services', 'NetworkOptimizations', 'DiskCleanup')]
    [String[]]
    $Optimizations,

    [Parameter()]
    [ValidateSet('All', 'Edge', 'RemoveLegacyIE', 'RemoveOneDrive')]
    [String[]]
    $AdvancedOptimizations,

    [Parameter()]
    [Switch]$Restart,

    [Parameter()]
    [Switch]$AcceptEULA
)
Begin
{
    # Windows Desktop Optimization Tool Version
    $WDOTVersion = '1.0.0.0'

    $HT = @{ ErrorAction = 'Stop' }
    $sHT = @{ ErrorAction = 'SilentlyContinue' }
    $EVT = @{ LogName = 'WDOT' ; Source = 'WDOT' }

    # Load all functions for later use
    Get-ChildItem -Path (Join-Path -Path "$($PSScriptRoot)" -ChildPath 'Functions\*-WDOT*.ps1') -File @sHT |
    ForEach-Object {
        Write-Verbose -Message "Loading function from $($_.FullName)"
        . "$($_.FullName)"
    }

    # Create Key
    $KeyPath = 'HKLM:\SOFTWARE\WDOT'
    If (-not(Test-Path $KeyPath -PathType Container))
    {
     try {
      $null = New-Item -Path $KeyPath -ItemType Container @HT
     } catch {
      Write-Warning -Message "Failed to create $($KeyPath) because $($_.Exception.Message)"
     }
    }

    # Add WDOT Version Key
    If (Get-ItemProperty -Path $KeyPath -Name Version @sHT)
    {
     try {
      Set-ItemProperty -Path $KeyPath -Name 'Version' -Value $WDOTVersion @HT
     } catch {
      Write-Warning -Message "Failed to set Version under $($KeyPath) because $($_.Exception.Message)"
     }
    }
    Else
    {
     try {
      New-ItemProperty -Path $KeyPath -Name 'Version' -Value $WDOTVersion @HT
     } catch {
      Write-Warning -Message "Failed to create Version under $($KeyPath) because $($_.Exception.Message)"
     }
    }

    # Add WDOT Last Run
    $LastRunValue = Get-Date
    If (Get-ItemProperty -Path $KeyPath -Name 'LastRunTime' @sHT)
    {
     try {
      Set-ItemProperty -Path $KeyPath -Name 'LastRunTime' -Value $LastRunValue @HT
     } catch {
      Write-Warning -Message "Failed to modify LastRunTime under $($KeyPath) because $($_.Exception.Message)"
     }
    }
    Else
    {
     try {
      $null = New-ItemProperty -Path $KeyPath -Name 'LastRunTime' -Value $LastRunValue @HT
     } catch {
      Write-Warning -Message "Failed to set LastRunTime under $($KeyPath) because $($_.Exception.Message)"
     }
    }

    $EventSources = @('WDOT', 'WindowsMediaPlayer', 'AppxPackages', 'ScheduledTasks', 'DefaultUserSettings', 'Autologgers', 'Services', 'LocalPolicy', 'NetworkOptimizations', 'AdvancedOptimizations', 'DiskCleanup')
    If (-not([System.Diagnostics.EventLog]::SourceExists('WDOT')))
    {
        # All WDOT main function Event ID's [1-9]
        New-EventLog -Source $EventSources @EVT @HT
        Limit-EventLog -OverflowAction OverWriteAsNeeded -MaximumSize 64KB @EVT @HT
        Write-EventLog @EVT  -EntryType Information -EventId 1 -Message "Log Created" @sHT
    }
    Else
    {
        New-EventLog -Source $EventSources @EVT @sHT
    }

    # Handle parameter set and validate configuration path
    if ($PSCmdlet.ParameterSetName -eq 'ByWindowsVersion')
    {
        Write-Warning -Message 'The -WindowsVersion parameter is deprecated and will be removed in a future release. Use -ConfigProfile instead.'
        $ConfigPath = $WindowsVersion
    }
    else
    {
        # Validate that ConfigProfile is provided and not empty
        if ([string]::IsNullOrWhiteSpace($ConfigProfile))
        {
            $AvailableConfigs = Get-ChildItem "$PSScriptRoot\Configurations" -Directory @sHT | Select-Object -ExpandProperty Name
            $ConfigList = if ($AvailableConfigs) { $AvailableConfigs -join ', ' } else { 'No configurations found' }

            $Message = @"
Configuration Profile is required but was not provided.

Usage: .\Windows_Optimization.ps1 -ConfigProfile <ProfileName> -Optimizations <OptimizationList>

Available Configuration Profiles: $ConfigList

Example: .\Windows_Optimization.ps1 -ConfigProfile "Windows11_24H2" -Optimizations All -AcceptEULA

To create a new configuration profile, use:
.\New-WVDConfigurationFiles.ps1 -FolderName "YourConfigName"
"@

            Write-Host -Object $Message -ForegroundColor Yellow
            Write-EventLog -Message 'Script execution failed: ConfigProfile parameter is required but was not provided.'  -EventID 101 -EntryType Error @EVT @sHT
            return
        }

        $ConfigPath = $ConfigProfile
    }

    Write-EventLog -EntryType Information -EventId 1 -Message "Starting WDOT by user '$env:USERNAME', for WDOT build '$ConfigPath', with the following options:`n$($PSBoundParameters | Out-String)" @EVT @sHT

    # Validate configuration path exists
    $WorkingLocation = Join-Path -Path "$($PSScriptRoot)" -ChildPath "Configurations\$($ConfigPath)"
    if (-not(Test-Path -Path $WorkingLocation -PathType Container))
    {
        $AvailableConfigs = Get-ChildItem -Path (Join-Path -Path "$($PSScriptRoot)" -ChildPath 'Configurations') -Directory @sHT | Select-Object -ExpandProperty Name
        $ConfigList = if ($AvailableConfigs) { $AvailableConfigs -join ', ' } else { 'No configurations found' }

        $Message = @"
Configuration Profile '$ConfigPath' not found at: $WorkingLocation

Available Configuration Profiles: $ConfigList

To create this configuration profile, use:
.\New-WVDConfigurationFiles.ps1 -FolderName "$ConfigPath"
"@

        Write-Host -Object $Message -ForegroundColor Red
        Write-EventLog -Message "Invalid configuration path: $WorkingLocation"  -EventID 100 -EntryType Error @EVT @sHT
        return
    }

    $StartTime = Get-Date
    $CurrentLocation = Get-Location

    try
    {
        Push-Location -Path $WorkingLocation -ErrorAction Stop
    }
    catch
    {
        $Message = "Failed to access configuration directory: $WorkingLocation - Exiting Script!"
        Write-EventLog -Message $Message -EventID 100 -EntryType Error @EVT @sHT
        Write-Host -Object $Message -ForegroundColor Red
        return
    }
}
Process {
    # Make sure we have something to process
    if (-not ($PSBoundParameters.Keys -match 'Optimizations') )
    {
        Write-EventLog -Message "No Optimizations (Optimizations or AdvancedOptimizations) passed, exiting script!"  -EventID 100 -EntryType Error @EVT @sHT
        $Message = "`nThe Optimizations parameter no longer defaults to 'All', you must explicitly pass in this parameter.`nThis is to allow for running 'AdvancedOptimizations' separately "
        Write-Host -Object ' * ' -ForegroundColor black -BackgroundColor yellow -NoNewline
        Write-Host -Object ' Important ' -ForegroundColor Yellow -BackgroundColor Red -NoNewline
        Write-Host -Object ' * ' -ForegroundColor black -BackgroundColor yellow -NoNewline
        Write-Host -Object $Message -ForegroundColor yellow -BackgroundColor black
        Return
    }

    # Legal stuff
    $EULA = Get-Content -Path (Join-Path -Path $PSScriptRoot -ChildPath 'EULA.txt') @sHT
    if (-not $AcceptEULA) {
        $Title = 'Accept EULA'
        $Options = @(
            New-Object System.Management.Automation.Host.ChoiceDescription "&Yes"
            New-Object System.Management.Automation.Host.ChoiceDescription "&No"
        )
        $Response = $host.UI.PromptForChoice($Title, $EULA, $Options, 0)
        if ($Response -eq 0) {
            Write-EventLog -EntryType Information -EventId 1 -Message 'EULA Accepted' @EVT @sHT
        } else {
            Write-EventLog -EntryType Warning -EventId 1 -Message 'EULA Declined, exiting!' @EVT @sHT
            Set-Location -Path $CurrentLocation
            $ScriptRunTime = New-TimeSpan -Start $StartTime -End (Get-Date)
            Write-EventLog -EntryType Information -EventId 1 -Message "WDOT Total Run Time: $($ScriptRunTime.Hours) Hours $($ScriptRunTime.Minutes) Minutes $($ScriptRunTime.Seconds) Seconds" @EVT @sHT
            Write-Host -Object "`n`nThank you from the Windows Desktop Optimization Team" -ForegroundColor Cyan
            continue
        }
    } else {
        Write-EventLog -EntryType Information -EventId 1 -Message 'EULA Accepted by Parameter' @EVT @sHT
    }

    #Get current OS stats
    $OSVersion = Get-WDOTOperatingSystemInfo
    New-WDOTCommentBox "$($OSVersion.Caption)`nVersion: $($OSVersion.DisplayVersion) - Release ID: $($OSVersion.ReleaseID)"

    #region Windows Media Player
    If ($Optimizations -contains 'WindowsMediaPlayer' -or $Optimizations -contains 'All')
    {
        Remove-WDOTWindowsMediaPlayer
    }
    #endregion

    #region APPX Packages
    If ($Optimizations -contains 'AppxPackages' -or $Optimizations -contains 'All')
    {
        Remove-WDOTAppxPackage
    }
    #endregion

    #region Disable Scheduled Tasks
    # This section is for disabling scheduled tasks.  If you find a task that should not be disabled
    # change its "VDIState" from Disabled to Enabled, or remove it from the json completely.
    If ($Optimizations -contains 'ScheduledTasks' -or $Optimizations -contains 'All')
    {
        Disable-WDOTScheduledTask
    }
    #endregion

    #region Customize Default User Profile
    # Apply appearance customizations to default user registry hive, then close hive file
    If ($Optimizations -contains 'DefaultUserSettings' -or $Optimizations -contains 'All')
    {
        Optimize-WDOTDefaultUserSetting
    }
    #endregion

    #region Disable Windows Traces
    If ($Optimizations -contains 'AutoLoggers' -or $Optimizations -contains 'All')
    {
        Disable-WDOTAutoLogger
    }
    #endregion

    #region Disable Services
    If ($Optimizations -contains 'Services' -or $Optimizations -contains 'All')
    {
        Disable-WDOTService
    }
    #endregion

    #region Network Optimization
    # LanManWorkstation optimizations
    If ($Optimizations -contains 'NetworkOptimizations' -or $Optimizations -contains 'All')
    {
        Optimize-WDOTNetworkOptimization
    }
    #endregion

    #region Local Group Policy Settings
    # - This code does not:
    #   * set a lock screen image.
    #   * change the "Root Certificates Update" policy.
    #   * change the "Enable Windows NTP Client" setting.
    #   * set the "Select when Quality Updates are received" policy
    If ($Optimizations -contains 'LocalPolicy' -or $Optimizations -contains 'All')
    {
        Optimize-WDOTLocalPolicySetting
    }
    #endregion

    #region Edge Settings
    If ($AdvancedOptimizations -contains 'Edge' -or $AdvancedOptimizations -contains 'All')
    {
        Optimize-WDOTEdgeSetting
    }
    #endregion

    #region Remove Legacy Internet Explorer
    If ($AdvancedOptimizations -contains 'RemoveLegacyIE' -or $AdvancedOptimizations -contains 'All')
    {
        Remove-WDOTRemoveLegacyIE
    }
    #endregion

    #region Remove OneDrive Commercial
    If ($AdvancedOptimizations -contains 'RemoveOneDrive' -or $AdvancedOptimizations -contains 'All')
    {
        Remove-WDOTRemoveOneDrive
    }
    #endregion

    #region Disk Cleanup
    # Delete not in-use files in locations C:\Windows\Temp and %temp%
    # Also sweep and delete *.tmp, *.etl, *.evtx, *.log, *.dmp, thumbcache*.db (not in use==not needed)
    # 5/18/20: Removing Disk Cleanup and moving some of those tasks to the following manual cleanup
    If ($Optimizations -contains 'DiskCleanup' -or $Optimizations -contains 'All')
    {
        Optimize-WDOTDiskCleanup
    }
    #endregion

    # Windows Desktop Optimization Toolkit cleanup
    Set-Location -Path $CurrentLocation
    $EndTime = Get-Date
    $ScriptRunTime = New-TimeSpan -Start $StartTime -End $EndTime
    Write-EventLog -EntryType Information -EventId 1 -Message "WDOT Total Run Time: $($ScriptRunTime.Hours) Hours $($ScriptRunTime.Minutes) Minutes $($ScriptRunTime.Seconds) Seconds" @EVT @sHT
    Write-Host -Object "`n`nThank you from the Windows Desktop Optimization Toolkit Team" -ForegroundColor Cyan

    If ($Restart)
    {
        Restart-Computer -Force
    }
    Else
    {
        Write-Warning -Message 'A reboot is required for all changes to take effect'
    }
}
End {
}