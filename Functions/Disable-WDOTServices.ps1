function Disable-WDOTService
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
        $ServicesFilePath = ".\Services.json"
        If (Test-Path $ServicesFilePath)
        {
            Write-EventLog -EventId 60 -Message "Disable Services" -LogName 'WDOT' -Source 'Services' -EntryType Information
            Write-Host "[VDI Optimize] Disable Services" -ForegroundColor Cyan
            $ServicesToDisable = (Get-Content $ServicesFilePath | ConvertFrom-Json ).Where( { $_.OptimizationState -eq 'Apply' })

            If ($ServicesToDisable.count -gt 0)
            {
                Write-EventLog -EventId 60 -Message "Processing Services Configuration File" -LogName 'WDOT' -Source 'Services' -EntryType Information
                Write-Verbose "Processing Services Configuration File"
                Foreach ($Item in $ServicesToDisable)
                {
                    Write-EventLog -EventId 60 -Message "Attempting to disable Service $($Item.Name) - $($Item.Description)" -LogName 'WDOT' -Source 'Services' -EntryType Information
                    Write-Verbose "Attempting to disable Service $($Item.Name) - $($Item.Description)"
                    Set-Service $Item.Name -StartupType Disabled
                }
            }
            Else
            {
                Write-EventLog -EventId 60 -Message "No Services found to disable" -LogName 'WDOT' -Source 'Services' -EntryType Warning
                Write-Verbose "No Services found to disable"
            }
        }
        Else
        {
            Write-EventLog -EventId 160 -Message "File not found: $ServicesFilePath" -LogName 'WDOT' -Source 'Services' -EntryType Error
            Write-Warning "File not found: $ServicesFilePath"
        }

    }
    End
    {
        Write-Verbose "Exiting Function '$($MyInvocation.MyCommand.Name)'"
    }
}
