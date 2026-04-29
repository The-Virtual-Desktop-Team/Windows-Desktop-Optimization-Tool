#Requires -RunAsAdministrator
Function Optimize-WDOTDefaultUserSetting {
    [CmdletBinding()]
    Param
    (
    [Parameter()]
    [string]$DefaultUserSettingsFilePath = ".\DefaultUserSettings.json"
    )
    Begin
    {
        Write-Verbose -Message "Entering Function '$($MyInvocation.MyCommand.Name)'"
        $HT = @{ ErrorAction = 'Stop' }
        $sHT = @{ ErrorAction = 'SilentlyContinue' }
        $EVT = @{ LogName = 'WDOT' ; Source = 'DefaultUserSettings' }
        $eId40Info  = @{ EventId = 40 ; EntryType = 'Information' }
        $eId40Warn  = @{ EventId = 40 ; EntryType = 'Warning' }
    }
    Process
    {
        If (Test-Path -Path $DefaultUserSettingsFilePath -PathType Leaf)
        {
         try {
            Write-EventLog -Message "Set Default User Settings" @EVT @eId40Info @sHT
            Write-Host -Object "[Windows Optimize] Set Default User Settings" -ForegroundColor Cyan
            $UserSettings = (Get-Content -Path $DefaultUserSettingsFilePath @HT | ConvertFrom-Json @HT).Where( { $_.OptimizationState -eq "Apply" })
            If ($UserSettings.Count -gt 0)
            {
                Write-EventLog -Message "Processing Default User Settings (Registry Keys)" @EVT @eId40Info @sHT
                Write-Verbose -Message "Processing Default User Settings (Registry Keys)"
                $null = Start-Process -FilePath "$($env:systemroot)\system32\reg.exe" -ArgumentList "LOAD HKLM\WDOT_TEMP C:\Users\Default\NTUSER.DAT" -PassThru -Wait
                if ($LASTEXITCODE -eq  0) {
                 Foreach ($Item in $UserSettings)
                 {
                    If ($Item.PropertyType -eq 'BINARY')
                    {
                        $Value = [byte[]]($Item.PropertyValue.Split(','))
                    }
                    Else
                    {
                        $Value = $Item.PropertyValue
                    }

                    If (Test-Path -Path "$($Item.HivePath)" -PathType Container)
                    {
                        Write-EventLog -Message "Found $($Item.HivePath) - $($Item.KeyName)" @EVT @eId40Info @sHT
                        Write-Verbose -Message "Found $($Item.HivePath) - $($Item.KeyName)"
                        If (Get-ItemProperty -Path "$($Item.HivePath)" -Name "$($Item.KeyName)" @sHT)
                        {
                            Write-EventLog -Message "Set $($Item.HivePath) - $Value" @EVT @eId40Info @sHT
                            try {
                             Set-ItemProperty -Path "$($Item.HivePath)" -Name "$($Item.KeyName)" -Value $Value -Type "$($Item.PropertyType)" -Force @HT
                            } catch {
                             Write-Warning -Message "Failed to set $($Item.KeyName) under key $($Item.HivePath) because $($_.Exception.Message)"
                            }
                        }
                        Else
                        {
                            Write-EventLog -Message "New $($Item.HivePath) Name $($Item.KeyName) PropertyType $($Item.PropertyType) Value $Value" @EVT @eId40Info @sHT
                            try {
                             $null = New-ItemProperty -Path "$($Item.HivePath)" -Name "$($Item.KeyName)" -PropertyType "$($Item.PropertyType)" -Value $Value -Force @HT
                            } catch {
                             Write-Warning -Message "Failed to create $($Item.KeyName) under key $($Item.HivePath) because $($_.Exception.Message)"
                            }
                        }
                    }
                    Else
                    {
                        Write-EventLog -Message "Registry Path not found $($Item.HivePath)" @EVT @eId40Info @sHT
                        Write-EventLog -Message "Creating new Registry Key $($Item.HivePath)" @EVT @eId40Info @sHT
                        try {
                         $newKey = New-Item -Path "$($Item.HivePath)" -ItemType 'Container' -Force @HT
                        } catch {
                         Write-Warning -Message "Failed to create key $($Item.HivePath) because $($_.Exception.Message)"
                        }
                        If (Test-Path -Path $newKey.PSPath -PathType Container)
                        {
                            try {
                             $null = New-ItemProperty -Path "$($Item.HivePath)" -Name "$($Item.KeyName)" -PropertyType "$($Item.PropertyType)" -Value $Value -Force @HT
                            } catch {
                             Write-Warning -Message "Failed to create $($Item.KeyName) under key $($Item.HivePath) because $($_.Exception.Message)"
                            }
                        }
                        Else
                        {
                            Write-EventLog -EventId 140 -Message "Failed to create new Registry Key" @EVT -EntryType Error @sHT
                        }
                    }
                 }
                } #endof LASTEXITCODE
                $null = Start-Process -FilePath "$($env:systemroot)\system32\reg.exe" -ArgumentList "UNLOAD HKLM\WDOT_TEMP" -PassThru -Wait @HT
            }
            Else
            {
                Write-EventLog -Message "No Default User Settings to set" @EVT @eId40Warn @sHT
            }

         } catch {
            Write-Warning -Message "Failed to set DefaultUserSettings because $($_.Exception.Message)"
         }
        }
        Else
        {
            Write-EventLog -Message "File not found: $DefaultUserSettingsFilePath" @EVT @eId40Warn @sHT
        }
    }
    End
    {
        Write-Verbose -Message "Exiting Function '$($MyInvocation.MyCommand.Name)'"
    }
}
