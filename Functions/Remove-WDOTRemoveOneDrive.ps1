#Requires -RunAsAdministrator
Function Remove-WDOTRemoveOneDrive
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
        EVT = @{ LogName = 'WDOT' ; Source = 'AdvancedOptimizations' }
    }
    Process
    {
        Write-EventLog -EventId 80 -Message "Remove OneDrive Commercial" @EVT -EntryType Information @sHT
        Write-Host -Object "Windows Advanced Optimize] Removing OneDrive Commercial" -ForegroundColor Cyan
        $OneDrivePath = @('C:\Windows\System32\OneDriveSetup.exe', 'C:\Windows\SysWOW64\OneDriveSetup.exe')
        $OneDrivePath | ForEach-Object {
            If (Test-Path -Path $_ -PathType Leaf)
            {
                Write-Host -Object "`tAttempting to uninstall $_"
                Write-EventLog -EventId 80 -Message "Commercial $_" @EVT -EntryType Information @sHT
                if ($PSCmdlet.ShouldProcess($_,'Start uninstall process')) {
                 try {
                  Start-Process -FilePath $_ -ArgumentList '/uninstall' -Wait @HT
                 } catch {
                  Write-Warning -Message "Failed to start uninstall process because $($_.Exception.Message)"
                 }
                }
            }
        }

        Write-EventLog -EventId 80 -Message "Removing shortcut links for OneDrive" @EVT -EntryType Information @sHT
        Get-ChildItem -Path 'C:\*' -Recurse -Force @sHT -Include 'OneDrive', 'OneDrive.exe', 'OneDrive.ico' |
        Where-Object { $_.FullName -notlike '*\WinSxS\*' } |
        Foreach-Object {
         $f = $_
         if ($PSCmdlet.ShouldProcess("$($f.FullName)",'Delete item')) {
          try {
           $f | Remove-Item -Force -Recurse @HT
          } catch {
           Write-Warning -Message "Failed to delete $($f.FullName) because $($_.Exception.Message)"
          }
         }
        }
    }
    End
    {
        Write-Verbose -Message "Exiting Function '$($MyInvocation.MyCommand.Name)'"
    }
}
