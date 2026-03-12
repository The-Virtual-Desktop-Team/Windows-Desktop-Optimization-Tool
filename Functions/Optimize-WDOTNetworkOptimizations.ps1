function Optimize-WDOTNetworkOptimization
{
    [CmdletBinding()]

    Param
    (

    )

    Begin
    {
        Write-Verbose "Entering Function '$($MyInvocation.MyCommand.Name)'"
    }
    Process
    {
        $NetworkOptimizationsFilePath = ".\LanManWorkstation.json"
        If (Test-Path $NetworkOptimizationsFilePath)
        {
            Write-EventLog -EventId 70 -Message "Configure LanManWorkstation Settings" -LogName 'WDOT' -Source 'NetworkOptimizations' -EntryType Information
            Write-Host "[Windows Optimize] Configure LanManWorkstation Settings" -ForegroundColor Cyan
            $LanManSettings = Get-Content $NetworkOptimizationsFilePath | ConvertFrom-Json
            If ($LanManSettings.Count -gt 0)
            {
                Write-EventLog -EventId 70 -Message "Processing LanManWorkstation Settings ($($LanManSettings.Count) Hives)" -LogName 'WDOT' -Source 'NetworkOptimizations' -EntryType Information
                Write-Verbose "Processing LanManWorkstation Settings ($($LanManSettings.Count) Hives)"
                Foreach ($Hive in $LanManSettings)
                {
                    If (Test-Path -Path $Hive.HivePath)
                    {
                        Write-EventLog -EventId 70 -Message "Found $($Hive.HivePath)" -LogName 'WDOT' -Source 'NetworkOptimizations' -EntryType Information
                        Write-Verbose "Found $($Hive.HivePath)"
                        $Keys = $Hive.Keys.Where{ $_.OptimizationState -eq "Apply" }
                        If ($Keys.Count -gt 0)
                        {
                            Write-EventLog -EventId 70 -Message "Create / Update LanManWorkstation Keys" -LogName 'WDOT' -Source 'NetworkOptimizations' -EntryType Information
                            Write-Verbose "Create / Update LanManWorkstation Keys"
                            Foreach ($Key in $Keys)
                            {
                                If (Get-ItemProperty -Path $Hive.HivePath -Name $Key.Name -ErrorAction SilentlyContinue)
                                {
                                    Write-EventLog -EventId 70 -Message "Setting $($Hive.HivePath) -Name $($Key.Name) -Value $($Key.PropertyValue)" -LogName 'WDOT' -Source 'NetworkOptimizations' -EntryType Information
                                    Write-Verbose "Setting $($Hive.HivePath) -Name $($Key.Name) -Value $($Key.PropertyValue)"
                                    Set-ItemProperty -Path $Hive.HivePath -Name $Key.Name -Value $Key.PropertyValue -Force
                                }
                                Else
                                {
                                    Write-EventLog -EventId 70 -Message "New $($Hive.HivePath) -Name $($Key.Name) -Value $($Key.PropertyValue)" -LogName 'WDOT' -Source 'NetworkOptimizations' -EntryType Information
                                    Write-Host "New $($Hive.HivePath) -Name $($Key.Name) -Value $($Key.PropertyValue)"
                                    New-ItemProperty -Path $Hive.HivePath -Name $Key.Name -PropertyType $Key.PropertyType -Value $Key.PropertyValue -Force | Out-Null
                                }
                            }
                        }
                        Else
                        {
                            Write-EventLog -EventId 70 -Message "No LanManWorkstation Keys to create / update" -LogName 'WDOT' -Source 'NetworkOptimizations' -EntryType Warning
                            Write-Warning "No LanManWorkstation Keys to create / update"
                        }
                    }
                    Else
                    {
                        Write-EventLog -EventId 70 -Message "Registry Path not found $($Hive.HivePath)" -LogName 'WDOT' -Source 'NetworkOptimizations' -EntryType Warning
                        Write-Warning "Registry Path not found $($Hive.HivePath)"
                    }
                }
            }
            Else
            {
                Write-EventLog -EventId 70 -Message "No LanManWorkstation Settings foun" -LogName 'WDOT' -Source 'NetworkOptimizations' -EntryType Warning
                Write-Warning "No LanManWorkstation Settings found"
            }
        }
        Else
        {
            Write-EventLog -EventId 70 -Message "File not found - $NetworkOptimizationsFilePath" -LogName 'WDOT' -Source 'NetworkOptimizations' -EntryType Warning
            Write-Warning "File not found - $NetworkOptimizationsFilePath"
        }

        if (Get-NetAdapterAdvancedProperty | Where-Object { $_.DisplayName -eq 'Send Buffer Size' }) {
         # NIC Advanced Properties performance settings for network biased environments
         Write-EventLog -EventId 70 -Message "Configuring Network Adapter Buffer Size" -LogName 'WDOT' -Source 'NetworkOptimizations' -EntryType Information
         Write-Host "[Windows Optimize] Configuring Network Adapter Buffer Size" -ForegroundColor Cyan

         Set-NetAdapterAdvancedProperty -DisplayName "Send Buffer Size" -DisplayValue 4MB -NoRestart
         <#  NOTE:
            Note that the above setting is for a Microsoft Hyper-V VM.  You can adjust these values in your environment...
            by querying in PowerShell using Get-NetAdapterAdvancedProperty, and then adjusting values using the...
            Set-NetAdapterAdvancedProperty command.
         #>
        }

    }
    End
    {
        Write-Verbose "Exiting Function '$($MyInvocation.MyCommand.Name)'"
    }
}
