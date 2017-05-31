## This script will restart a VM that is no longer responding to heartbeats
## It was made to run as a scheduled task

## Run this as a scheduled task with the following task settings:
#### Program/Script: C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe
#### Add arguments: "C:\Scripts\RestartVM39.ps1" -executionpolicy bypass (not needed if properly signed)

## Set the Hyper-V VM Name here
$VMName = "Server 01"

$VM = Get-VMIntegrationService -VMName $VMName -Name Heartbeat
if ($VM.PrimaryStatusDescription -ne "OK")
{
    write-host "VM Dead ? restarting ..."
    Stop-VM $VMName -Force -TurnOff
    Start-VM $VMName
}