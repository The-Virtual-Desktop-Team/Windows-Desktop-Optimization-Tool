Function Get-WDOTOperatingSystemInfo {
 [CmdletBinding()]
 Param ()
 Begin {
  Write-Verbose -Message "Entering Function '$($MyInvocation.MyCommand.Name)'"
  $HT = @{ ErrorAction = 'Stop' }
 }
 Process {
  try {
   $CIMOSInfo = Get-CimInstance -ClassName 'Win32_OperatingSystem' @HT |
   Select-Object -Property 'Caption','Version'
   $RegOSInfo = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' @HT |
   Select-Object -Property 'CurrentVersion','CurrentBuildNumber','DisplayVersion','ReleaseID'
   [PSCustomObject]@{
    Caption = $CIMOSInfo.Caption
    Version = $CIMOSInfo.Version
    CurrentVersion = $RegOSInfo.CurrentVersion
    CurrentBuildNumber = $RegOSInfo.CurrentBuildNumber
    DisplayVersion = $RegOSInfo.DisplayVersion
    ReleaseID = $RegOSInfo.ReleaseID
   }
  } catch {
   Write-Warning -Message "Failed to get OSinfo because $($_.Exception.Message)"
  }
 }
 End {
  Write-Verbose -Message "Exiting Function '$($MyInvocation.MyCommand.Name)'"
 }
}