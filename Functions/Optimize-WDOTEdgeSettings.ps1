Function Optimize-WDOTEdgeSetting
{
    [CmdletBinding()]

    Param
    (
  [Parameter()]
  [string]$EdgeFilePath = ".\EdgeSettings.json"
    )

    Begin
    {
        Write-Verbose -Message "Entering Function '$($MyInvocation.MyCommand.Name)'"
        $HT = @{ ErrorAction = 'Stop' }
        $sHT = @{ ErrorAction = 'SilentlyContinue' }
        $EVT = @{ LogName = 'WDOT' ; Source = 'AdvancedOptimizations' }
        $eId80Info  = @{ EventId = 80 ; EntryType = 'Information' }
        $eId80Warn  = @{ EventId = 80 ; EntryType = 'Warning' }
    }
    Process
    {

        If (Test-Path -Path $EdgeFilePath -PathType Leaf)
        {
try {
            Write-EventLog -Message "Edge Policy Settings" @EVT @sHT @eId80Info
            Write-Host -Object "[Windows Advanced Optimize] Edge Policy Settings" -ForegroundColor Cyan
            $EdgeSettings = Get-Content -Path $EdgeFilePath @HT | ConvertFrom-Json @HT
            If ($EdgeSettings.Count -gt 0)
            {
                Write-EventLog -Message "Processing Edge Policy Settings ($($EdgeSettings.Count) Hives)" @EVT @sHT @eId80Info
                Write-Verbose -Message "Processing Edge Policy Settings ($($EdgeSettings.Count) Hives)"
                Foreach ($Key in $EdgeSettings)
                {
                    If ($Key.OptimizationState -eq 'Apply')
                    {
                        If ($key.RegItemValueName -eq 'DefaultAssociationsConfiguration')
                        {
                            try {
                             Copy-Item -Path .\ConfigurationFiles\DefaultAssociationsConfiguration.xml $key.RegItemValue -Force @HT
                            } catch {
                             Write-Warning -Message "Failed to copy file because $($_.Exception.Message)"
                            }
                        }
                        If (Get-ItemProperty -Path $Key.RegItemPath -Name $Key.RegItemValueName @sHT)
                        {
                            Write-EventLog -Message "Found key, $($Key.RegItemPath) Name $($Key.RegItemValueName) Value $($Key.RegItemValue)" @EVT @sHT @eId80Info
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
                                Write-EventLog -Message "Path found, creating new property -Path $($Key.RegItemPath) -Name $($Key.RegItemValueName) -PropertyType $($Key.RegItemValueType) -Value $($Key.RegItemValue)" @EVT @sHT @eId80Info
                                Write-Verbose -Message "Path found, creating new property -Path $($Key.RegItemPath) Name $($Key.RegItemValueName) PropertyType $($Key.RegItemValueType) Value $($Key.RegItemValue)"
                                try {
                                 $null = New-ItemProperty -Path $Key.RegItemPath -Name $Key.RegItemValueName -PropertyType $Key.RegItemValueType -Value $Key.RegItemValue -Force @HT
                                } catch {
                                 Write-Warning -Message "Faile to create $($Key.RegItemValueName) under $($Key.RegItemPath) because $($_.Exception.Message)"
                                }
                            }
                            Else
                            {
                                Write-EventLog -Message "Creating Key and Path" @EVT @sHT @eId80Info
                                Write-Verbose -Message 'Creating Key and Path'
                                try {
                                 $null = New-Item -Path $Key.RegItemPath -Force -ItemType Container @HT |
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
                Write-EventLog -Message 'No Edge Policy Settings Found!' @EVT @sHT @eId80Warn
                Write-Warning -Message 'No Edge Policy Settings found'
            }
         } catch {
          Write-Warning -Message "Failed to set Edge Settings because $($_.Exception.Message)"
         }
        }

    }
    End
    {
        Write-Verbose -Message "Exiting Function '$($MyInvocation.MyCommand.Name)'"
    }
}
