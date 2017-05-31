## Set servers which this script can connect to
$exchangeserver = "server.domain.com"

## Credentials for Azure
Write-Host "Which credentials will you use for Exchange?" -ForegroundColor Red
$credential = Get-Credential

## Do Exchange Online stuff
Write-Host "Connecting to Exchange Online..." -ForegroundColor Red
$ExchangeSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $credential -Authentication Basic -AllowRedirection

Import-PSSession $ExchangeSession

$DistroName = Read-Host 'Enter Dynamic Distribution Group Name'
$FTE = Get-DynamicDistributionGroup "$DistroName"
Get-Recipient -RecipientPreviewFilter $FTE.RecipientFilter | fl Identity
Remove-PSSession $ExchangeSession

Read-Host "Press any key to exit..."
exit