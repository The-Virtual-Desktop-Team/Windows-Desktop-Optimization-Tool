#Requires -RunAsAdministrator
Function Optimize-WDOTLocalPolicySetting
{
    [CmdletBinding()]
    Param
    (
    [Parameter()]
    [string]$LocalPolicyFilePath = ".\PolicyRegSettings.json"
    )
    Begin
    {
        Write-Verbose -Message "Entering Function '$($MyInvocation.MyCommand.Name)'"
        $HT = @{ ErrorAction = 'Stop' }
        $sHT = @{ ErrorAction = 'SilentlyContinue' }
        $EVT = @{ LogName = 'WDOT' ; Source = 'LocalPolicy' }
        $eId80Info  = @{ EventId = 80 ; EntryType = 'Information' }
        $eId80Warn  = @{ EventId = 80 ; EntryType = 'Warning' }
    }
    Process
    {
        If (Test-Path -Path $LocalPolicyFilePath -PathType Leaf)
        {
            Write-EventLog -Message "Local Policy Items" @EVT @eId80Info @sHT
            Write-Host -Object "[Windows Optimize] Local Group Policy Items" -ForegroundColor Cyan
            try {
             $PolicyRegSettings = Get-Content -Path $LocalPolicyFilePath @HT | ConvertFrom-Json @HT
             If ($PolicyRegSettings.Count -gt 0)
             {
                Write-EventLog -Message "Processing PolicyRegSettings Settings ($($PolicyRegSettings.Count) Hives)" @EVT @eId80Info @sHT
                Write-Verbose -Message "Processing PolicyRegSettings Settings ($($PolicyRegSettings.Count) Hives)"
                Foreach ($Key in $PolicyRegSettings)
                {
                    If ($Key.OptimizationState -eq 'Apply')
                    {
                        If (Get-ItemProperty -Path $Key.RegItemPath -Name $Key.RegItemValueName @sHT)
                        {
                            Write-EventLog -Message "Found key, $($Key.RegItemPath) Name $($Key.RegItemValueName) Value $($Key.RegItemValue)" @EVT @eId80Info @sHT
                            Write-Verbose -Message "Found key, $($Key.RegItemPath) Name $($Key.RegItemValueName) Value $($Key.RegItemValue)"
                            try {
                             Set-ItemProperty -Path $Key.RegItemPath -Name $Key.RegItemValueName -Value $Key.RegItemValue -Force @HT
                            } catch {
                             Write-Warning -Message "Failed to set $($Key.RegItemValueName) under $($Key.RegItemPath) because $($_.Exception.Message)"
                            }
                        }
                        Else
                        {
                            If (Test-path -Path $Key.RegItemPath -PathType Container)
                            {
                                Write-EventLog -Message "Path found, creating new property -Path $($Key.RegItemPath) -Name $($Key.RegItemValueName) -PropertyType $($Key.RegItemValueType) -Value $($Key.RegItemValue)" @EVT @eId80Info @sHT
                                Write-Verbose -Message "Path found, creating new property -Path $($Key.RegItemPath) Name $($Key.RegItemValueName) PropertyType $($Key.RegItemValueType) Value $($Key.RegItemValue)"
                                try {
                                 $null = New-ItemProperty -Path $Key.RegItemPath -Name $Key.RegItemValueName -PropertyType $Key.RegItemValueType -Value $Key.RegItemValue -Force @HT
                                } catch {
                                 Write-Warning -Message "Failed to create $($Key.RegItemValueName) under $($Key.RegItemPath) because $($_.Exception.Message)"
                                }
                            }
                            Else
                            {
                                Write-EventLog -Message "Error: Creating Name $($Key.RegItemValueName), Value $($Key.RegItemValue) and Path $($Key.RegItemPath)" @EVT @eId80Info @sHT
                                Write-Verbose -Message "Error: Creating Name $($Key.RegItemValueName), Value $($Key.RegItemValue) and Path $($Key.RegItemPath)"
                                try {
                                 $null = New-Item -Path $Key.RegItemPath -Force @HT |
                                 New-ItemProperty -Name $Key.RegItemValueName -PropertyType $Key.RegItemValueType -Value $Key.RegItemValue -Force @HT
                                } catch {
                                 Write-Warning -Message "Failed to add $($Key.RegItemValueName) under $($Key.RegItemPath) because $($_.Exception.Message)"
                                }
                            }
                        }
                    }
                }
             }
             Else
             {
                Write-EventLog -Message 'No LocalPolicy Settings Found!' @EVT @eId80Warn @sHT
                Write-Warning -Message 'No LocalPolicy Settings found'
             }
            } catch  {
             Write-Warning -Message "Failed to set LocalPolicy Settings because $($_.Exception.Message)"
            }

        }

    }
    End
    {
        Write-Verbose -Message "Exiting Function '$($MyInvocation.MyCommand.Name)'"
    }
}
