#Requires -RunAsAdministrator
Function Optimize-WDOTDiskCleanup {
    [CmdletBinding()]
    Param()
    Begin
    {
        Write-Verbose -Message "Entering Function '$($MyInvocation.MyCommand.Name)'"
        $sHT = @{ ErrorAction = 'SilentlyContinue' }
        EVT = @{ LogName = 'WDOT' ; Source = 'DiskCleanup' }
    }
    Process
    {
        try
        {
            Write-EventLog -EventId 90 -Message "Removing .tmp, .etl, .evtx, thumbcache*.db, *.log files not in use" @EVT -EntryType Information @sHT
            Write-Verbose -Message 'Removing .tmp, .etl, .evtx, thumbcache*.db, *.log files not in use'
            Get-ChildItem -Path 'C:\' -Include *.tmp, *.dmp, *.etl, *.evtx, thumbcache*.db, *.log -File -Recurse -Force @sHT | Remove-Item @sHT

            # Delete "RetailDemo" content (if it exits)
            Write-EventLog -EventId 90 -Message "Removing Retail Demo content (if it exists)" @EVT -EntryType Information @sHT
            Write-Verbose -Message 'Removing Retail Demo content (if it exists)'
            Get-ChildItem -Path $env:ProgramData\Microsoft\Windows\RetailDemo\* -Recurse -Force @sHT | Remove-Item -Recurse @sHT

            # Delete not in-use anything in the C:\Windows\Temp folder
            Write-EventLog -EventId 90 -Message "Removing all files not in use in $env:windir\TEMP" @EVT -EntryType Information @sHT
            Write-Verbose -Message "Removing all files not in use in $env:windir\TEMP"
            Remove-Item -Path $env:windir\Temp\* -Recurse -Force @sHT -Exclude packer*.ps1

            # Clear out Windows Error Reporting (WER) report archive folders
            Write-EventLog -EventId 90 -Message "Cleaning up WER report archive" @EVT -EntryType Information @sHT
            Write-Verbose -Message 'Cleaning up WER report archive'
            Remove-Item -Path $env:ProgramData\Microsoft\Windows\WER\Temp\* -Recurse -Force @sHT
            Remove-Item -Path $env:ProgramData\Microsoft\Windows\WER\ReportArchive\* -Recurse -Force @sHT
            Remove-Item -Path $env:ProgramData\Microsoft\Windows\WER\ReportQueue\* -Recurse -Force @sHT

            # Delete not in-use anything in your %temp% folder
            Write-EventLog -EventId 90 -Message "Removing files not in use in $env:temp directory" @EVT -EntryType Information @sHT
            Write-Verbose -Message "Removing files not in use in $env:temp directory"
            Remove-Item -Path $env:TEMP\* -Recurse -Force @sHT -Exclude packer*.ps1

            # Clear out ALL visible Recycle Bins
            Write-EventLog -EventId 90 -Message 'Clearing out ALL Recycle Bins' @EVT -EntryType Information @sHT
            Write-Verbose -Message 'Clearing out ALL Recycle Bins'
            Clear-RecycleBin -Force @sHT

            # Clear out BranchCache cache
            Write-EventLog -EventId 90 -Message 'Clearing BranchCache cache' @EVT -EntryType Information @sHT
            Write-Verbose -Message 'Clearing BranchCache cache'
            Clear-BCCache -Force @sHT
        }
        catch
        {
            Write-Warning -Message "DiskCleanup encountered a non-critical error: $($_.Exception.Message)"
        }

    }
    End
    {
        Write-Verbose -Message "Exiting Function '$($MyInvocation.MyCommand.Name)'"
    }
}
