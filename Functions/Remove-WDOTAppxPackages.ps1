#Requires -RunAsAdministrator
Function Remove-WDOTAppxPackage
{
    [CmdletBinding(SupportsShouldProcess)]
    Param
    (
  [Parameter()]
  [string]$AppxConfigFilePath = ".\AppxPackages.json"
    )

    Begin
    {
        Write-Verbose -Message "Entering Function '$($MyInvocation.MyCommand.Name)'"
  $HT = @{ ErrorAction = 'Stop' }
  $sHT = @{ ErrorAction = 'SilentlyContinue' }
  $EVT = @{ LogName = 'WDOT' ; Source = 'AppxPackages' }

    }

    Process
    {

        If (Test-Path -Path $AppxConfigFilePath -PathType Leaf)
        {
            Write-EventLog -EventId 20 -Message "[Windows Optimize] Removing Appx Packages" @EVT -EntryType Information @sHT
            Write-Host -Object "[Windows Optimize] Removing Appx Packages" -ForegroundColor Cyan
            $AppxPackage = (Get-Content -Path $AppxConfigFilePath @HT | ConvertFrom-Json @HT).Where( { $_.OptimizationState -eq 'Apply' })
            If ($AppxPackage.Count -gt 0)
            {
                Foreach ($Item in $AppxPackage)
                {
                    try
                    {
                        Write-EventLog -EventId 20 -Message "Removing Provisioned Package $($Item.AppxPackage)" @EVT -EntryType Information @sHT
                        Write-Verbose -Message "Removing Provisioned Package $($Item.AppxPackage)"
                        Get-AppxProvisionedPackage -Online @HT | Where-Object { $_.PackageName -like ("*{0}*" -f $Item.AppxPackage) } |
                        Foreach-Object {
                         $p = $_
                         if ($PSCmdlet.ShouldProcess($p.DisplayName,'Remove Provisioned Package')) {
                          try {
                           $null = Remove-AppxProvisionedPackage -PackageName $p.PackageName -Online @HT
                          } catch {
                           Write-Warning -Message "Failed to remove provisioned package $($p.DisplayName) because $($_.Exception.Message)"
                          }
                         }
                        }
                        Write-EventLog -EventId 20 -Message "Attempting to remove [All Users] $($Item.AppxPackage) - $($Item.Description)" @EVT -EntryType Information @sHT
                        Write-Verbose -Message "Attempting to remove [All Users] $($Item.AppxPackage) - $($Item.Description)"
                        Get-AppxPackage -AllUsers -Name ("*{0}*" -f $Item.AppxPackage) @HT |
                        Foreach-Object {
                         $p = $_
                         if ($PSCmdlet.ShouldProcess($p.Name,'Remove AllUsers package')) {
                          try {
                           $null = $p | Remove-AppxPackage -AllUsers @HT
                          } catch {
                           Write-Warning -Message "Failed to remove AllUsers package $($p.Name) because $($_.Exception.Message)"
                          }
                         }
                        }
                        Write-EventLog -EventId 20 -Message "Attempting to remove $($Item.AppxPackage) - $($Item.Description)" @EVT -EntryType Information @sHT
                        Write-Verbose -Message "Attempting to remove $($Item.AppxPackage) - $($Item.Description)"
                        Get-AppxPackage -Name ("*{0}*" -f $Item.AppxPackage) @HT |
                        Foreach-Object {
                         $p = $_
                         if ($PSCmdlet.ShouldProcess($p.Name,'Remove CurrentUser package')) {
                          try {
                           $null = $p | Remove-AppxPackage @HT
                          } catch {
                           Write-Warning -Message "Failed to remove CurrentUser package $($p.Name) because $($_.Exception.Message)"
                          }
                         }
                        }
                    }
                    catch
                    {
                        Write-EventLog -EventId 120 -Message "Failed to remove Appx Package $($Item.AppxPackage) - $($_.Exception.Message)" @EVT -EntryType Error @sHT
                        Write-Warning -Message "Failed to remove Appx Package $($Item.AppxPackage) - $($_.Exception.Message)"
                    }
                }
            }
            Else
            {
                Write-EventLog -EventId 20 -Message "No AppxPackages found to disable" @EVT -EntryType Warning @sHT
                Write-Warning -Message "No AppxPackages found to disable in $AppxConfigFilePath"
            }
        }
        Else
        {

            Write-EventLog -EventId 20 -Message "Configuration file not found - $AppxConfigFilePath" @EVT -EntryType Warning @sHT
            Write-Warning -Message "Configuration file not found -  $AppxConfigFilePath"
        }

    }

    End
    {
        Write-Verbose -Message "Exiting Function '$($MyInvocation.MyCommand.Name)'"
    }
}