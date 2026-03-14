#Requires -RunAsAdministrator
Function Disable-WDOTService {
    [CmdletBinding()]
    Param
    (
     [Parameter()]
     [string]$ServicesFilePath = ".\Services.json"
    )
    Begin
    {
        Write-Verbose -Message "Entering Function '$($MyInvocation.MyCommand.Name)'"
        $HT = @{ ErrorAction = 'Stop' }
        $sHT = @{ ErrorAction = 'SilentlyContinue' }
        EVT = @{ LogName = 'WDOT' ; Source = 'AdvancedOptimizations' }
    }
    Process
    {
        If (Test-Path -Path $ServicesFilePath -PathType Leaf)
        {
         try {
            Write-EventLog -EventId 60 -Message "Disable Services" @EVT -EntryType Information
            Write-Host -Object "[VDI Optimize] Disable Services" -ForegroundColor Cyan
            $ServicesToDisable = (Get-Content -Path $ServicesFilePath @HT | ConvertFrom-Json @HT).Where( { $_.OptimizationState -eq 'Apply' })

            If ($ServicesToDisable.count -gt 0)
            {
                Write-EventLog -EventId 60 -Message "Processing Services Configuration File" @EVT -EntryType Information @sHT
                Write-Verbose -Message 'Processing Services Configuration File'
                Foreach ($Item in $ServicesToDisable)
                {
                    Write-EventLog -EventId 60 -Message "Attempting to disable Service $($Item.Name) - $($Item.Description)" @EVT -EntryType Information @sHT
                    Write-Verbose -Message "Attempting to disable Service $($Item.Name) - $($Item.Description)"
                    try {
                     Set-Service -Name $Item.Name -StartupType Disabled @HT
                    } catch {
                     Write-Warning -Message "Failed to change startup type of $($Item.Name) because $($_.Exception.Message)"
                    }
                }
            }
            Else
            {
                Write-EventLog -EventId 60 -Message "No Services found to disable" @EVT -EntryType Warning @sHT
                Write-Verbose -Message 'No Services found to disable'
            }
         } catch {
          Write-Warning -Message "Failed to change services because $($_.Exception.Message)"
         }
        }
        Else
        {
            Write-EventLog -EventId 160 -Message "File not found: $ServicesFilePath" @EVT -EntryType Error @sHT
            Write-Warning -Message "File not found: $ServicesFilePath"
        }

    }
    End
    {
        Write-Verbose -Message "Exiting Function '$($MyInvocation.MyCommand.Name)'"
    }
}
