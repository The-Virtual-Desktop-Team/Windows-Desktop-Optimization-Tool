#Requires -RunAsAdministrator
Function Optimize-WDOTNetworkOptimization
{
    [CmdletBinding()]
    Param
    (
    [Parameter()]
    [string]$NetworkOptimizationsFilePath = ".\LanManWorkstation.json"
    )
    Begin
    {
        Write-Verbose -Message "Entering Function '$($MyInvocation.MyCommand.Name)'"
        $HT = @{ ErrorAction = 'Stop' }
        $sHT = @{ ErrorAction = 'SilentlyContinue' }
        $EVT = @{ LogName = 'WDOT' ; Source = 'DefaultUserSettings' }
        $eId70Info  = @{ EventId = 40 ; EntryType = 'Information' }
        $eId70Warn  = @{ EventId = 40 ; EntryType = 'Warning' }
    }
    Process
    {
        If (Test-Path -Path $NetworkOptimizationsFilePath -PathType Leaf)
        {
         try {
            Write-EventLog -Message "Configure LanManWorkstation Settings" @EVT @eId70Info @sHT
            Write-Host -Object "[Windows Optimize] Configure LanManWorkstation Settings" -ForegroundColor Cyan
            $LanManSettings = Get-Content $NetworkOptimizationsFilePath  @HT | ConvertFrom-Json @HT
            If ($LanManSettings.Count -gt 0)
            {
                Write-EventLog -Message "Processing LanManWorkstation Settings ($($LanManSettings.Count) Hives)" @EVT @eId70Info @sHT
                Write-Verbose -Message "Processing LanManWorkstation Settings ($($LanManSettings.Count) Hives)"
                Foreach ($Hive in $LanManSettings)
                {
                    If (Test-Path -Path $Hive.HivePath -PathType Container)
                    {
                        Write-EventLog -Message "Found $($Hive.HivePath)" @EVT @eId70Info @sHT
                        Write-Verbose -Message "Found $($Hive.HivePath)"
                        $Keys = $Hive.Keys.Where{ $_.OptimizationState -eq 'Apply' }
                        If ($Keys.Count -gt 0)
                        {
                            Write-EventLog -Message 'Create / Update LanManWorkstation Keys' @EVT @eId70Info @sHT
                            Write-Verbose -Message 'Create / Update LanManWorkstation Keys'
                            Foreach ($Key in $Keys)
                            {
                                If (Get-ItemProperty -Path $Hive.HivePath -Name $Key.Name @sHT)
                                {
                                    Write-EventLog -Message "Setting $($Hive.HivePath) -Name $($Key.Name) -Value $($Key.PropertyValue)" @EVT @eId70Info @sHT
                                    Write-Verbose -Message "Setting $($Hive.HivePath) -Name $($Key.Name) -Value $($Key.PropertyValue)"
                                    try {
                                     Set-ItemProperty -Path $Hive.HivePath -Name $Key.Name -Value $Key.PropertyValue -Force @HT
                                    } catch {
                                     Write-Warning -Message "Failed to set $($Key.Name) under $($Hive.HivePath) because $($_.Exception.Message)"
                                    }
                                }
                                Else
                                {
                                    Write-EventLog -Message "New $($Hive.HivePath) -Name $($Key.Name) -Value $($Key.PropertyValue)" @EVT @eId70Info @sHT
                                    Write-Host -Object "New $($Hive.HivePath) -Name $($Key.Name) -Value $($Key.PropertyValue)"
                                    try {
                                     $null = New-ItemProperty -Path $Hive.HivePath -Name $Key.Name -PropertyType $Key.PropertyType -Value $Key.PropertyValue -Force @HT
                                    } catch {
                                     Write-Warning -Message "Failed to create $($Key.Name) under $($Hive.HivePath) because $($_.Exception.Message)"
                                    }
                                }
                            }
                        }
                        Else
                        {
                            Write-EventLog -Message 'No LanManWorkstation Keys to create / update' @EVT @eId70Warn @sHT
                            Write-Warning -Message 'No LanManWorkstation Keys to create / update'
                        }
                    }
                    Else
                    {
                        Write-EventLog -Message "Registry Path not found $($Hive.HivePath)" @EVT @eId70Warn @sHT
                        Write-Warning -Message "Registry Path not found $($Hive.HivePath)"
                    }
                }
            }
            Else
            {
                Write-EventLog -Message 'No LanManWorkstation Settings found' @EVT @eId70Warn @sHT
                Write-Warning -Message 'No LanManWorkstation Settings found'
            }
         } catch {
          Write-Warning -Message "Failed to set LanManWorkstation Settings because $($_.Exception.Message)"
         }
        }
        Else
        {
            Write-EventLog -Message "File not found - $($NetworkOptimizationsFilePath)" @EVT @eId70Warn @sHT
            Write-Warning -Message "File not found - $($NetworkOptimizationsFilePath)"
        }

        # NIC Advanced Properties performance settings for network biased environments
        if (Get-NetAdapterAdvancedProperty | Where-Object { $_.DisplayName -eq 'Send Buffer Size' }) {
         Write-EventLog -Message "Configuring Network Adapter Buffer Size" @EVT @eId70Info @sHT
         Write-Host -Object "[Windows Optimize] Configuring Network Adapter Buffer Size" -ForegroundColor Cyan
         try {
          Set-NetAdapterAdvancedProperty -DisplayName "Send Buffer Size" -DisplayValue 4MB -NoRestart @HT
         } catch {
          Write-Waring -Message "Failed to set Send Buffer Size because $($_.Exception.Message)"
         }
         <#  NOTE:
            Note that the above setting is for a Microsoft Hyper-V VM.  You can adjust these values in your environment...
            by querying in PowerShell using Get-NetAdapterAdvancedProperty, and then adjusting values using the...
            Set-NetAdapterAdvancedProperty command.
         #>
        }
    }
    End
    {
        Write-Verbose -Message "Exiting Function '$($MyInvocation.MyCommand.Name)'"
    }
}
