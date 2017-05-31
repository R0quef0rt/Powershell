## This script is used to run a scheduled task that syncs the Azure AD Connect tool between DOMAIN.com and Microsoft Azure

$azureserver = "server.domain.com"

Invoke-Command -ComputerName $azureserver {Start-ADSyncSyncCycle -PolicyType Delta}
