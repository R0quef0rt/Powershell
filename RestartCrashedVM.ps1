## This script will restart a VM that is no longer responding to heartbeats
## It was made to run as a scheduled task

## Set the Hyper-V VM Name here
$VMName = "VM01"

$VM = Get-VMIntegrationService -VMName $VMName -Name Heartbeat
if ($VM.PrimaryStatusDescription -ne "OK")
{
    write-host "VM Dead ? restarting ..."
    Stop-VM $VMName -Force -TurnOff
    Start-VM $VMName (OpenDNS)"
}