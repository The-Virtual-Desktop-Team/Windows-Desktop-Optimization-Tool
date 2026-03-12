function Optimize-WDOTLocalPolicySetting
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
        $LocalPolicyFilePath = ".\PolicyRegSettings.json"
        If (Test-Path $LocalPolicyFilePath)
        {
            Write-EventLog -EventId 80 -Message "Local Policy Items" -LogName 'WDOT' -Source 'LocalPolicy' -EntryType Information
            Write-Host "[Windows Optimize] Local Group Policy Items" -ForegroundColor Cyan
            $PolicyRegSettings = Get-Content $LocalPolicyFilePath | ConvertFrom-Json
            If ($PolicyRegSettings.Count -gt 0)
            {
                Write-EventLog -EventId 80 -Message "Processing PolicyRegSettings Settings ($($PolicyRegSettings.Count) Hives)" -LogName 'WDOT' -Source 'LocalPolicy' -EntryType Information
                Write-Verbose "Processing PolicyRegSettings Settings ($($PolicyRegSettings.Count) Hives)"
                Foreach ($Key in $PolicyRegSettings)
                {
                    If ($Key.OptimizationState -eq 'Apply')
                    {
                        If (Get-ItemProperty -Path $Key.RegItemPath -Name $Key.RegItemValueName -ErrorAction SilentlyContinue)
                        {
                            Write-EventLog -EventId 80 -Message "Found key, $($Key.RegItemPath) Name $($Key.RegItemValueName) Value $($Key.RegItemValue)" -LogName 'WDOT' -Source 'LocalPolicy' -EntryType Information
                            Write-Verbose "Found key, $($Key.RegItemPath) Name $($Key.RegItemValueName) Value $($Key.RegItemValue)"
                            Set-ItemProperty -Path $Key.RegItemPath -Name $Key.RegItemValueName -Value $Key.RegItemValue -Force
                        }
                        Else
                        {
                            If (Test-path $Key.RegItemPath)
                            {
                                Write-EventLog -EventId 80 -Message "Path found, creating new property -Path $($Key.RegItemPath) -Name $($Key.RegItemValueName) -PropertyType $($Key.RegItemValueType) -Value $($Key.RegItemValue)" -LogName 'WDOT' -Source 'LocalPolicy' -EntryType Information
                                Write-Verbose "Path found, creating new property -Path $($Key.RegItemPath) Name $($Key.RegItemValueName) PropertyType $($Key.RegItemValueType) Value $($Key.RegItemValue)"
                                New-ItemProperty -Path $Key.RegItemPath -Name $Key.RegItemValueName -PropertyType $Key.RegItemValueType -Value $Key.RegItemValue -Force | Out-Null
                            }
                            Else
                            {
                                Write-EventLog -EventId 80 -Message "Error: Creating Name $($Key.RegItemValueName), Value $($Key.RegItemValue) and Path $($Key.RegItemPath)" -LogName 'WDOT' -Source 'LocalPolicy' -EntryType Information
                                Write-Verbose "Error: Creating Name $($Key.RegItemValueName), Value $($Key.RegItemValue) and Path $($Key.RegItemPath)"
                                New-Item -Path $Key.RegItemPath -Force | New-ItemProperty -Name $Key.RegItemValueName -PropertyType $Key.RegItemValueType -Value $Key.RegItemValue -Force | Out-Null
                            }

                        }
                    }
                }
            }
            Else
            {
                Write-EventLog -EventId 80 -Message "No LocalPolicy Settings Found!" -LogName 'WDOT' -Source 'LocalPolicy' -EntryType Warning
                Write-Warning "No LocalPolicy Settings found"
            }
        }

    }
    End
    {
        Write-Verbose "Exiting Function '$($MyInvocation.MyCommand.Name)'"
    }
}
