<#	
  .Synopsis
      This powershell script copies the WS1 Win10 Migration script and AirwatchAgent.msi files to C:\Temp\WS1Win10Migration & executes WS1Win10Migration.ps1
  .NOTES
      Created:   	February, 2021
      Created by:	Phil Helmling, @philhelmling
      Organization: VMware, Inc.
      Filename:     DeployFiles.ps1
  .DESCRIPTION
      This powershell script copies the WS1 Win10 Migration script and AirwatchAgent.msi files to C:\Temp\WS1Win10Migration & executes WS1Win10Migration.ps1
  .REQUIREMENTS
      AirwatchAgent.msi must be included in package
  .EXAMPLE
      Install Command
      powershell.exe -ep bypass -file .\DeployFiles.ps1 -scriptname WS1Win10Migration.ps1 -username USERNAME -password PASSWORD -Server DESTINATION_SERVER_FQDN -OGName DESTINATION_OG_NAME

      Uninstall Command
      .

      When to Call Install Complete
      File Exists: C:\Temp\WS1Win10Migration\WS1Win10Migration.ps1
#>
param (
  [Parameter(Mandatory=$true)]
  [string]$scriptname=$script:scriptname,
  [Parameter(Mandatory=$true)]
  [string]$username=$script:Username,
  [Parameter(Mandatory=$true)]
  [string]$password=$script:password,
  [Parameter(Mandatory=$true)]
  [string]$OGName=$script:OGName,
  [Parameter(Mandatory=$true)]
  [string]$Server=$script:Server
)

$current_path = $PSScriptRoot;
if($PSScriptRoot -eq ""){
    #PSScriptRoot only popuates if the script is being run.  Default to default location if empty
    $current_path = "C:\Temp";
}

$1 = (Get-Item "$current_path\$script:scriptname").BaseName
$deploypath = "C:\Temp\$1"

function Invoke-CreateTask{
    #Get Current time to set Scheduled Task to run powershell
    $DateTime = (Get-Date).AddMinutes(5).ToString("HH:mm")

    $PShellScript = `"$deploypath\$script:scriptname`" -username `"$script:username`" -password `"$script:password`" -Server `"$script:Server`" -OGName `"$script:OGName`"
    $arg = '-ExecutionPolicy Bypass -File "' + $PShellScript + '"'
    $TaskName = "WS1Win10Migration"
    Try{
        $A = New-ScheduledTaskAction -Execute "C:\Windows\System32\WindowsPowerShell\v1.0\Powershell.exe" -Argument $arg 
        $T = New-ScheduledTaskTrigger -Once -RandomDelay "00:05" -At $DateTime
        PS C:\>Register-ScheduledTask Task01 -Action $Sta -Trigger $Stt
        
        $P = New-ScheduledTaskPrincipal "System" -RunLevel Highest
        $S = New-ScheduledTaskSettingsSet -Hidden -AllowStartIfOnBatteries -StartWhenAvailable -Priority 5
        $S.CimInstanceProperties['MultipleInstances'].Value=3
        $D = New-ScheduledTask -Action $A -Principal $P -Trigger $T -Settings $S

        Register-ScheduledTask -InputObject $D -TaskName $Taskname -Force -ErrorAction Stop
    } Catch {
        #$e = $_.Exception.Message;
        Write-Host "Error: Job creation failed.  Validate user rights.";
    }
    #Don't start the task, let this complete and start in 5 minutes to let this process end, and SFDAgent to close the process, that way it will uninstall properly
    #Start-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath;
}

#Copy package files
If(!(test-path $deploypath)){
	New-Item -ItemType Directory -Force -Path $deploypath
}
Copy-Item -Path "$current_path\*.*" -Destination $deploypath -Force -Recurse

#Create Scheduled Task to run the main program
Invoke-CreateTask

#Call Migration Script with parameters
#& "powershell.exe" -ep bypass -file `"$deploypath\$script:scriptname`" -username `"$script:username`" -password `"$script:password`" -Server `"$script:Server`" -OGName `"$script:OGName`"
