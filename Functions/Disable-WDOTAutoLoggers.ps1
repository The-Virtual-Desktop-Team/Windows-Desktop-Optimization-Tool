#Requires -RunAsAdministrator
Function Disable-WDOTAutoLogger {
 [CmdletBinding()]
 Param(
  [Parameter()]
  [string]$AutoLoggersFilePath = ".\Autologgers.Json"
 )
 Begin {
  Write-Verbose -Message "Entering Function '$($MyInvocation.MyCommand.Name)'"
  $HT = @{ ErrorAction = 'Stop' }
  $sHT = @{ ErrorAction = 'SilentlyContinue' }
  $EVT = @{ LogName = 'WDOT' ; Source = 'AutoLoggers' }
 }
 Process {
        If (Test-Path -Path $AutoLoggersFilePath -PathType Leaf) {
            Write-EventLog -EventId 50 -Message 'Disable AutoLoggers' -EntryType Information @EVT @sHT
            Write-Host -Object "[Windows Optimize] Disable Autologgers" -ForegroundColor Cyan
            try {
             $DisableAutologgers = (Get-Content -Path $AutoLoggersFilePath @HT | ConvertFrom-Json @HT).Where({ $_.OptimizationState -eq 'Apply' })
             Write-Verbose -Message "Successfully read Autologgers from $($AutoLoggersFilePath)"
            } catch {
             Write-Warning -Message "Failed to read Autologgers from $($AutoLoggersFilePath) because $($_.Exception.Message)"
            }
            If ($DisableAutologgers.count -gt 0) {
                Write-EventLog -EventId 50 -Message "Disable AutoLoggers" -EntryType Information @EVT  @sHT
                Write-Verbose -Message 'Processing Autologger Configuration File'
                $DisableAutologgers |
                Foreach-Object {
                    $Item = $_
                    Write-EventLog -EventId 50 -Message "Updating Registry Key for: $($Item.KeyName)" -EntryType Information @EVT @sHT
                    Write-Verbose -Message "Updating Registry Key for: $($Item.KeyName)"
                    try {
                        $null = New-ItemProperty -Path ("{0}" -f $Item.KeyName) -Name 'Start' -PropertyType 'DWORD' -Value 0 -Force @HT
                        Write-Verbose -Message "Successfully disabled autologger: $(Split-Path -Path $Item.KeyName -Leaf)"
                    } catch {
                        Write-Warning -Message "Failed to add $($Item.KeyName) because $($_.Exception.Message)"
                        Write-EventLog -EventId 150 -Message "Failed to add $($Item.KeyName)`n`n $($_.Exception.Message)" -EntryType Error @EVT @sHT
                    }
                }
            } else {
                Write-EventLog -EventId 50 -Message 'No Autologgers found to disable' -EntryType Warning @EVT @sHT
                Write-Verbose -Message 'No Autologgers found to disable'
            }
        } else {
            Write-EventLog -EventId 150 -Message "File not found: $AutoLoggersFilePath" -EntryType Error @EVT @sHT
            Write-Warning -Message "File Not Found: $AutoLoggersFilePath"
        }
 }
 End {
        Write-Verbose -Message "Exiting Function '$($MyInvocation.MyCommand.Name)'"
 }
}
