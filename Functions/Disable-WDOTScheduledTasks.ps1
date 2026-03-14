#Requires -RunAsAdministrator
Function Disable-WDOTScheduledTask {
    [CmdletBinding()]
    Param
    (
     [Parameter()]
     [string]$ScheduledTasksFilePath = ".\ScheduledTasks.json"
    )
    Begin
    {
        Write-Verbose -Message "Entering Function '$($MyInvocation.MyCommand.Name)'"
        $HT = @{ ErrorAction = 'Stop' }
        $sHT = @{ ErrorAction = 'SilentlyContinue' }
        EVT = @{ LogName = 'WDOT' ; Source = 'ScheduledTasks' }
    }
    Process
    {
        If (Test-Path -Path $ScheduledTasksFilePath -PathType Leaf)
        {
            Write-EventLog -EventId 30 -Message "[Windows Optimize] Disable Scheduled Tasks" @EVT -EntryType Information @sHT
            Write-Host -Object "[Windows Optimize] Disable Scheduled Tasks" -ForegroundColor Cyan
            $SchTasksList = (Get-Content -Path $ScheduledTasksFilePath @HT | ConvertFrom-Json @HT).Where( { $_.OptimizationState -eq 'Apply' })
            If ($SchTasksList.count -gt 0)
            {
                Foreach ($Item in $SchTasksList)
                {
                    $TaskObject = Get-ScheduledTask -TaskName $Item.ScheduledTask @sHT
                    If ($TaskObject -and $TaskObject.State -ne 'Disabled')
                    {
                        Write-EventLog -EventId 30 -Message "Attempting to disable Scheduled Task: $($TaskObject.TaskName)" @EVT -EntryType Information @sHT
                        Write-Verbose -Message "Attempting to disable Scheduled Task: $($TaskObject.TaskName)"
                        try
                        {
                            $null = Disable-ScheduledTask -InputObject $TaskObject @HT
                            Write-EventLog -EventId 30 -Message "Disabled Scheduled Task: $($TaskObject.TaskName)" @EVT -EntryType Information @sHT
                        }
                        catch
                        {
                            Write-EventLog -EventId 130 -Message "Failed to disabled Scheduled Task: $($TaskObject.TaskName) - $($_.Exception.Message)" @EVT -EntryType Error @sHT
                        }
                    }
                    ElseIf ($TaskObject -and $TaskObject.State -eq 'Disabled')
                    {
                        Write-EventLog -EventId 30 -Message "$($TaskObject.TaskName) Scheduled Task is already disabled - $($_.Exception.Message)" @EVT -EntryType Warning @sHT
                    }
                    Else
                    {
                        Write-EventLog -EventId 130 -Message "Unable to find Scheduled Task: $($TaskObject.TaskName) - $($_.Exception.Message)" @EVT -EntryType Error @sHT
                    }
                }
            }
            Else
            {
                Write-EventLog -EventId 30 -Message "No Scheduled Tasks found to disable" @EVT -EntryType Warning @sHT
            }
        }
        Else
        {
            Write-EventLog -EventId 30 -Message "File not found! -  $ScheduledTasksFilePath" @EVT -EntryType Warning @sHT
        }
    }
    End
    {
        Write-Verbose -Message "Exiting Function '$($MyInvocation.MyCommand.Name)'"
    }
}
