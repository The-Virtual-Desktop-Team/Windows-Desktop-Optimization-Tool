function Optimize-WDOTEdgeSetting
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
        $EdgeFilePath = ".\EdgeSettings.json"
        If (Test-Path $EdgeFilePath)
        {
            Write-EventLog -EventId 80 -Message "Edge Policy Settings" -LogName 'WDOT' -Source 'AdvancedOptimizations' -EntryType Information
            Write-Host "[Windows Advanced Optimize] Edge Policy Settings" -ForegroundColor Cyan
            $EdgeSettings = Get-Content $EdgeFilePath | ConvertFrom-Json
            If ($EdgeSettings.Count -gt 0)
            {
                Write-EventLog -EventId 80 -Message "Processing Edge Policy Settings ($($EdgeSettings.Count) Hives)" -LogName 'WDOT' -Source 'AdvancedOptimizations' -EntryType Information
                Write-Verbose "Processing Edge Policy Settings ($($EdgeSettings.Count) Hives)"
                Foreach ($Key in $EdgeSettings)
                {
                    If ($Key.OptimizationState -eq 'Apply')
                    {
                        If ($key.RegItemValueName -eq 'DefaultAssociationsConfiguration')
                        {
                            Copy-Item .\ConfigurationFiles\DefaultAssociationsConfiguration.xml $key.RegItemValue -Force
                        }
                        If (Get-ItemProperty -Path $Key.RegItemPath -Name $Key.RegItemValueName -ErrorAction SilentlyContinue)
                        {
                            Write-EventLog -EventId 80 -Message "Found key, $($Key.RegItemPath) Name $($Key.RegItemValueName) Value $($Key.RegItemValue)" -LogName 'WDOT' -Source 'AdvancedOptimizations' -EntryType Information
                            Write-Verbose "Found key, $($Key.RegItemPath) Name $($Key.RegItemValueName) Value $($Key.RegItemValue)"
                            Set-ItemProperty -Path $Key.RegItemPath -Name $Key.RegItemValueName -Value $Key.RegItemValue -Force
                        }
                        Else
                        {
                            If (Test-path $Key.RegItemPath)
                            {
                                Write-EventLog -EventId 80 -Message "Path found, creating new property -Path $($Key.RegItemPath) -Name $($Key.RegItemValueName) -PropertyType $($Key.RegItemValueType) -Value $($Key.RegItemValue)" -LogName 'WDOT' -Source 'AdvancedOptimizations' -EntryType Information
                                Write-Verbose "Path found, creating new property -Path $($Key.RegItemPath) Name $($Key.RegItemValueName) PropertyType $($Key.RegItemValueType) Value $($Key.RegItemValue)"
                                New-ItemProperty -Path $Key.RegItemPath -Name $Key.RegItemValueName -PropertyType $Key.RegItemValueType -Value $Key.RegItemValue -Force | Out-Null
                            }
                            Else
                            {
                                Write-EventLog -EventId 80 -Message "Creating Key and Path" -LogName 'WDOT' -Source 'AdvancedOptimizations' -EntryType Information
                                Write-Verbose "Creating Key and Path"
                                New-Item -Path $Key.RegItemPath -Force | New-ItemProperty -Name $Key.RegItemValueName -PropertyType $Key.RegItemValueType -Value $Key.RegItemValue -Force | Out-Null
                            }

                        }
                    }
                }
            }
            Else
            {
                Write-EventLog -EventId 80 -Message "No Edge Policy Settings Found!" -LogName 'WDOT' -Source 'AdvancedOptimizations' -EntryType Warning
                Write-Warning "No Edge Policy Settings found"
            }
        }
        Else
        {
            # nothing to do here"
        }

    }
    End
    {
        Write-Verbose "Exiting Function '$($MyInvocation.MyCommand.Name)'"
    }
}
