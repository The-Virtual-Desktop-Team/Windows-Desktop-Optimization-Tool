#Requires -RunAsAdministrator
Function Remove-WDOTWindowsMediaPlayer
{
    [CmdletBinding(SupportsShouldProcess)]
    Param ()
    Begin
    {
        Write-Verbose -Message "Entering Function '$($MyInvocation.MyCommand.Name)'"
        $HT = @{ ErrorAction = 'Stop' }
        $sHT = @{ ErrorAction = 'SilentlyContinue' }
        EVT = @{ LogName = 'WDOT' ; Source = 'WindowsMediaPlayer' }
    }
    Process
    {
        try
        {
            Write-EventLog -EventId 10 -Message "[Windows Optimize] Disable / Remove Windows Media Player" @EVT -EntryType Information @sHT
            Write-Host -Object "[Windows Optimize] Disable / Remove Windows Media Player" -ForegroundColor Cyan
            if ($PSCmdlet.ShouldProcess('WindowsMediaPlayer','Disable feature')) {
             try {
              $null = Disable-WindowsOptionalFeature -Online -FeatureName WindowsMediaPlayer -NoRestart @HT
             } catch {
              Write-Warning -Message "Failed to disable WindowsMediaPlayer feature because $($_.Exception.Message)"
             }
            }
            Get-WindowsPackage -Online -PackageName "*Windows-mediaplayer*" @HT |
            ForEach-Object {
                Write-EventLog -EventId 10 -Message "Removing $($_.PackageName)" @EVT -EntryType Information @sHT
                $p = $_
                if ($PSCmdlet.ShouldProcess("$($_.PackageName)",'Remove package')) {
                 try {
                  $null = Remove-WindowsPackage -PackageName $_.PackageName -Online @HT -NoRestart
                 } catch {
                  Write-Warning -Message "Failed to remove package $($p.PackageName) because $($_.Exception.Message)"
                 }
                }
            }
        }
        catch
        {
            Write-Warning -Message "Failed to remove Media Player because $($_.Exception.Message)"
            Write-EventLog -EventId 110 -Message "Disabling / Removing Windows Media Player - $($_.Exception.Message)" @EVT -EntryType Error @sHT
        }
    }
    End
    {
        Write-Verbose -Message "Exiting Function '$($MyInvocation.MyCommand.Name)'"
    }
}