Function Remove-WDOTAppxPackage
{
    [CmdletBinding(SupportsShouldProcess)]
    Param
    (

    )

    Begin
    {
        Write-Verbose "Entering Function '$($MyInvocation.MyCommand.Name)'"
    }

    Process
    {
        $AppxConfigFilePath = ".\AppxPackages.json"
        If (Test-Path $AppxConfigFilePath)
        {
            Write-EventLog -EventId 20 -Message "[Windows Optimize] Removing Appx Packages" -LogName 'WDOT' -Source 'AppxPackages' -EntryType Information
            Write-Host "[Windows Optimize] Removing Appx Packages" -ForegroundColor Cyan
            $AppxPackage = (Get-Content $AppxConfigFilePath | ConvertFrom-Json).Where( { $_.OptimizationState -eq 'Apply' })
            If ($AppxPackage.Count -gt 0)
            {
                Foreach ($Item in $AppxPackage)
                {
                    try
                    {
                        Write-EventLog -EventId 20 -Message "Removing Provisioned Package $($Item.AppxPackage)" -LogName 'WDOT' -Source 'AppxPackages' -EntryType Information
                        Write-Verbose "Removing Provisioned Package $($Item.AppxPackage)"
                        Get-AppxProvisionedPackage -Online | Where-Object { $_.PackageName -like ("*{0}*" -f $Item.AppxPackage) } |
                        Foreach-Object {
                         $p = $_
                         if ($PSCmdlet.ShouldProcess($p.DisplayName,'Remove Provisioned Package')) {
                          try {
                           $null = Remove-AppxProvisionedPackage -PackageName $p.PackageName -Online -ErrorAction Stop
                          } catch {
                           Write-Warning -Message "Failed to remove provisioned package $($p.DisplayName) because $($_.Exception.Message)"
                          }
                         }
                        }
                        Write-EventLog -EventId 20 -Message "Attempting to remove [All Users] $($Item.AppxPackage) - $($Item.Description)" -LogName 'WDOT' -Source 'AppxPackages' -EntryType Information
                        Write-Verbose "Attempting to remove [All Users] $($Item.AppxPackage) - $($Item.Description)"
                        Get-AppxPackage -AllUsers -Name ("*{0}*" -f $Item.AppxPackage) |
                        Foreach-Object {
                         $p = $_
                         if ($PSCmdlet.ShouldProcess($p.Name,'Remove AllUsers package')) {
                          try {
                           $null = $p | Remove-AppxPackage -AllUsers -ErrorAction Stop
                          } catch {
                           Write-Warning -Message "Failed to remove AllUsers package $($p.Name) because $($_.Exception.Message)"
                          }
                         }
                        }
                        Write-EventLog -EventId 20 -Message "Attempting to remove $($Item.AppxPackage) - $($Item.Description)" -LogName 'WDOT' -Source 'AppxPackages' -EntryType Information
                        Write-Verbose "Attempting to remove $($Item.AppxPackage) - $($Item.Description)"
                        Get-AppxPackage -Name ("*{0}*" -f $Item.AppxPackage) |
                        Foreach-Object {
                         $p = $_
                         if ($PSCmdlet.ShouldProcess($p.Name,'Remove CurrentUser package')) {
                          try {
                           $null = $p | Remove-AppxPackage -ErrorAction Stop
                          } catch {
                           Write-Warning -Message "Failed to remove CurrentUser package $($p.Name) because $($_.Exception.Message)"
                          }
                         }
                        }
                    }
                    catch
                    {
                        Write-EventLog -EventId 120 -Message "Failed to remove Appx Package $($Item.AppxPackage) - $($_.Exception.Message)" -LogName 'WDOT' -Source 'AppxPackages' -EntryType Error
                        Write-Warning "Failed to remove Appx Package $($Item.AppxPackage) - $($_.Exception.Message)"
                    }
                }
            }
            Else
            {
                Write-EventLog -EventId 20 -Message "No AppxPackages found to disable" -LogName 'WDOT' -Source 'AppxPackages' -EntryType Warning
                Write-Warning "No AppxPackages found to disable in $AppxConfigFilePath"
            }
        }
        Else
        {

            Write-EventLog -EventId 20 -Message "Configuration file not found - $AppxConfigFilePath" -LogName 'WDOT' -Source 'AppxPackages' -EntryType Warning
            Write-Warning "Configuration file not found -  $AppxConfigFilePath"
        }

    }

    End
    {
        Write-Verbose "Exiting Function '$($MyInvocation.MyCommand.Name)'"
    }
}