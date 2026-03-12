function Optimize-WDOTDefaultUserSetting
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
        $DefaultUserSettingsFilePath = ".\DefaultUserSettings.json"
        If (Test-Path $DefaultUserSettingsFilePath)
        {
            Write-EventLog -EventId 40 -Message "Set Default User Settings" -LogName 'WDOT' -Source 'WDOT' -EntryType Information
            Write-Host "[Windows Optimize] Set Default User Settings" -ForegroundColor Cyan
            $UserSettings = (Get-Content $DefaultUserSettingsFilePath | ConvertFrom-Json).Where( { $_.OptimizationState -eq "Apply" })
            If ($UserSettings.Count -gt 0)
            {
                Write-EventLog -EventId 40 -Message "Processing Default User Settings (Registry Keys)" -LogName 'WDOT' -Source 'DefaultUserSettings' -EntryType Information
                Write-Verbose "Processing Default User Settings (Registry Keys)"
                $null = Start-Process reg -ArgumentList "LOAD HKLM\WDOT_TEMP C:\Users\Default\NTUSER.DAT" -PassThru -Wait

                Foreach ($Item in $UserSettings)
                {
                    If ($Item.PropertyType -eq "BINARY")
                    {
                        $Value = [byte[]]($Item.PropertyValue.Split(","))
                    }
                    Else
                    {
                        $Value = $Item.PropertyValue
                    }

                    If (Test-Path -Path ("{0}" -f $Item.HivePath))
                    {
                        Write-EventLog -EventId 40 -Message "Found $($Item.HivePath) - $($Item.KeyName)" -LogName 'WDOT' -Source 'DefaultUserSettings' -EntryType Information
                        Write-Verbose "Found $($Item.HivePath) - $($Item.KeyName)"
                        If (Get-ItemProperty -Path ("{0}" -f $Item.HivePath) -ErrorAction SilentlyContinue)
                        {
                            Write-EventLog -EventId 40 -Message "Set $($Item.HivePath) - $Value" -LogName 'WDOT' -Source 'DefaultUserSettings' -EntryType Information
                            Set-ItemProperty -Path ("{0}" -f $Item.HivePath) -Name $Item.KeyName -Value $Value -Type $Item.PropertyType -Force
                        }
                        Else
                        {
                            Write-EventLog -EventId 40 -Message "New $($Item.HivePath) Name $($Item.KeyName) PropertyType $($Item.PropertyType) Value $Value" -LogName 'WDOT' -Source 'DefaultUserSettings' -EntryType Information
                            New-ItemProperty -Path ("{0}" -f $Item.HivePath) -Name $Item.KeyName -PropertyType $Item.PropertyType -Value $Value -Force | Out-Null
                        }
                    }
                    Else
                    {
                        Write-EventLog -EventId 40 -Message "Registry Path not found $($Item.HivePath)" -LogName 'WDOT' -Source 'DefaultUserSettings' -EntryType Information
                        Write-EventLog -EventId 40 -Message "Creating new Registry Key $($Item.HivePath)" -LogName 'WDOT' -Source 'DefaultUserSettings' -EntryType Information
                        $newKey = New-Item -Path ("{0}" -f $Item.HivePath) -Force
                        If (Test-Path -Path $newKey.PSPath)
                        {
                            New-ItemProperty -Path ("{0}" -f $Item.HivePath) -Name $Item.KeyName -PropertyType $Item.PropertyType -Value $Value -Force | Out-Null
                        }
                        Else
                        {
                            Write-EventLog -EventId 140 -Message "Failed to create new Registry Key" -LogName 'WDOT' -Source 'DefaultUserSettings' -EntryType Error
                        }
                    }
                }
                $null = Start-Process reg -ArgumentList "UNLOAD HKLM\WDOT_TEMP" -PassThru -Wait
            }
            Else
            {
                Write-EventLog -EventId 40 -Message "No Default User Settings to set" -LogName 'WDOT' -Source 'DefaultUserSettings' -EntryType Warning
            }
        }
        Else
        {
            Write-EventLog -EventId 40 -Message "File not found: $DefaultUserSettingsFilePath" -LogName 'WDOT' -Source 'DefaultUserSettings' -EntryType Warning
        }
    }
    End
    {
        Write-Verbose "Exiting Function '$($MyInvocation.MyCommand.Name)'"
    }
}
