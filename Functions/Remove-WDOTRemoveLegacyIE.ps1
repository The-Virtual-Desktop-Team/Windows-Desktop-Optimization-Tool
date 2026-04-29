#Requires -RunAsAdministrator
Function Remove-WDOTRemoveLegacyIE
{
    [CmdletBinding(SupportsShouldProcess)]

    Param
    (

    )

    Begin
    {
        Write-Verbose -Message "Entering Function '$($MyInvocation.MyCommand.Name)'"
        $HT = @{ ErrorAction = 'Stop' }
        $sHT = @{ ErrorAction = 'SilentlyContinue' }
    }
    Process
    {
      try {
        Write-EventLog -EventId 80 -Message "Remove Legacy Internet Explorer" -LogName 'WDOT' -Source 'AdvancedOptimizations' -EntryType Information @sHT
        Write-Host -Object "[Windows Advanced Optimize] Remove Legacy Internet Explorer" -ForegroundColor Cyan
        Get-WindowsCapability -Online @HT | Where-Object { $_.Name -Like "*Browser.Internet*" } |
        Foreach-Object {
         $c = $_
         if ($PSCmdlet.ShouldProcess($c.Name,'Remove Capability')) {
          try {
           $c | Remove-WindowsCapability -Online @HT
          } catch {
           Write-Warning -Message "Failed to remove capability $($c.Name) because $($_.Exception.Message)"
          }
         }
        }
      } catch {
       Write-Warning -Message "Failed to remove capability because $($_.Exception.Message)"
      }
    }
    End
    {
        Write-Verbose -Message "Exiting Function '$($MyInvocation.MyCommand.Name)'"
    }
}
