############# Many of the sleep timers could be fixed by properly targetting a DC

##### This script requires the Microsoft Online Services Sign-In Assistant, as well as the Azure Active Directory Module for Powershell


#### could be improved by running Azure commands on remote machine, rather than relying upon locally installed components to run. Invoke-Command would be better.

## Load functions from other scripts

. ".\OUPicker.ps1"
Write-Host "Loaded OUPicker.ps1"
. ".\ActiveDirectory\New-SWRandomPassword.ps1"
Write-Host "Loaded New-SWRandomPassword.ps1"


## Set servers which this script can connect to
$domaincontroller = "server01.domain.com"
$exchangeserver = "server02.domain.com"
$azureserver = "server03.domain.com"

## Set SMTP Server variables
$smtpServer="smtp.domain.com" 
$from = "Service Desk <alerts@domain.com>" 

## Credentials for Azure
Write-Host "Which credentials will you use for Azure?" -ForegroundColor Red
$credential = Get-Credential



## Capture employee information

Write-Host "Tell me more about the new user" -ForegroundColor Red
$FirstName = Read-Host -Prompt "First Name"
$LastName = Read-Host -Prompt "Last Name"
$Initials = Read-Host -Prompt "Middle Initial (leave blank if none)"
$officephone = Read-Host -Prompt "Office phone"
$extension = Read-Host -Prompt "Office extension"
$fax = Read-Host -Prompt "Fax number"
$cellphone = Read-Host -Prompt "Cell phone"
$homefolder = "\\domain.com\HomeFolders\$FirstName$LastName"
$usertitle = Read-Host -Prompt "What is the employee's title?" 

## These options could be more dynamic

$LogonDomain = "domain.com"
$userPrincipalName = "$FirstName.$LastName@$logonDomain"
$department = Read-Host -Prompt "Department"
$company = Read-Host -Prompt "Company"

## Prompt user to choose a market

Write-Host "Please choose the user's primary market of operation" -ForegroundColor Red
$title = "Send Method"
$message = "Set primary market"
$a = New-Object System.Management.Automation.Host.ChoiceDescription "&A", `
    "Houston, TX"
$b = New-Object System.Management.Automation.Host.ChoiceDescription "&B", `
    "Dallas, TX"
$c = New-Object System.Management.Automation.Host.ChoiceDescription "&C", `
    "Beaumont, TX"

$options = [System.Management.Automation.Host.ChoiceDescription[]]($a, $b, $c)
$result = $host.ui.PromptForChoice($title, $message, $options, 0)
 
switch ($result)
    {
        0 {"You set Houston, TX"}
        1 {"You set Dallas, TX."}
        2 {"You set Beaumont, TX."}
}

if ($result -eq "0") {
    $market = "Houston, TX"
    $city = "Houston"
    $state = "TX"
    } elseif ($result -eq "1") {
    $market = "Dallas, TX"
    $city = "Dallas"
    $state = "TX"
    } elseif ($result -eq "2") {
    $market = "Beaumont, TX"
    $city = "Beaumont"
    $state = "TX"
    } else { 
}

Write-Host "Where should we place the user?" -ForegroundColor Red
$OU = Browse-AD

$managerlookup = Read-Host -Prompt "Who does this employee report to? Searching by first and last name works best"

$otheruserlookup = Read-Host -Prompt "Who should we copy security permissions from? Searching by first and last name works best"

Write-Host "Where should we send an email notification to? The direct manager will be automatically CC'd." -ForegroundColor Red
$emailaddress = Read-Host -Prompt "Personal Email Address"








## This uses the New-SWRandomPassword.ps1 script to generate a secure password, and store it as a variable
$password = New-SWRandomPassword -InputStrings abcdefghijklmnopqrstuvwxyz, ABCDEFGHIJKLMNOPQRSTUVWXYZ, 1234567890 -PasswordLength 12






## Connect to Remote Powershell on the Exchange 2016 Hybrid server

Write-Host "Connecting to the local Exchange 2016 Hybrid environment..." -ForegroundColor Red
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://$exchangeserver/PowerShell/ -Authentication Kerberos
Import-PSSession $Session

## Create Mailbox

Write-Host "Creating mailbox..." -ForegroundColor Red
New-RemoteMailbox -FirstName $FirstName -LastName $LastName -Initials $Initials -Name "$FirstName $LastName" -DisplayName "$FirstName $LastName" -OnPremisesOrganizationalUnit $OU -Password (ConvertTo-SecureString -AsPlainText "$password" -Force) -ResetPasswordOnNextLogon $true -UserPrincipalName "$userPrincipalName" -Archive -DomainController $domaincontroller
Remove-PSSession $Session






## Do AD Stuff.

Write-Host "Mailbox created. Connecting to the local Active Directory environment..." -ForegroundColor Red
Import-Module ActiveDirectory
Write-Host "Waiting for Active Directory to update with the newly-created user account..." -ForegroundColor Red
Start-Sleep -s 30
$sAMAccountName = Get-ADUser -LDAPFilter "(userprincipalname=$userPrincipalName)" | foreach { $_.samaccountname }




##choose manager

$manager = Get-ADUser -LDAPFilter "(name=$managerlookup)" | foreach { $_.distinguishedname }
$manageremail = Get-ADUser -LDAPFilter "(name=$managerlookup)" -Properties mail | select mail | foreach { $_.mail }
$managermobile = get-ADUser -LDAPFilter "(name=$managerlookup)" -Properties MobilePhone| select mobilephone | foreach { $_.mobilephone }
$managername = Get-ADUser -LDAPFilter "(name=$managerlookup)" | foreach { $_.name }
Write-Host "You've selected $managername as the manager" -ForegroundColor Red

## Set AD Attributes
Set-ADUser -Identity $sAMAccountName -HomeDrive "Q:" -HomeDirectory "$homefolder" -City $city -State $state -Company $company -Department $department -Title $usertitle
Try { Set-ADUser -Identity $sAMAccountName -OfficePhone "$officephone $extension" } 
  Catch { write-host "Skipping office phone..." }
Try { Set-ADUser -Identity $sAMAccountName -Identity $sAMAccountName -MobilePhone $cellphone } 
  Catch { write-host "Skipping mobile phone..." }
Try { Set-ADUser -Identity $sAMAccountName -Identity $sAMAccountName -Fax $fax } 
  Catch { write-host "Skipping fax..." }
Try { Set-ADUser -Identity $sAMAccountName -Manager $manager } 
  Catch { write-host "Failed to find a the manager specified..." }

## Set security groups
Write-Host "Setting security permissions..." -ForegroundColor Red

$otherusersam = Get-ADUser -LDAPFilter "(name=$otheruserlookup)" | foreach { $_.samaccountname }
Write-Host "You chose to copy permissions from $otheruserlookup..." -ForegroundColor Red

Get-ADUser -Identity $otherusersam -Properties memberof | Select-Object -ExpandProperty memberof | Add-ADGroupMember -Members $sAMAccountName -PassThru | Select-Object -Property SamAccountName





## Runs a dirsync to move user into Azure
Invoke-Command -ComputerName $azureserver {Start-ADSyncSyncCycle -PolicyType Delta}
Write-Host "Waiting 300 seconds for local Active Directory to sync with Microsoft Azure..." -ForegroundColor Red
Start-Sleep -s 300



## Connect to $azureserver. This is required in order to run commands against Azure without the need to install components locally.

Write-Host "Signing in to Microsoft Azure..." -ForegroundColor Red

Import-Module MsOnline
Connect-MsolService -Credential $credential

Start-Sleep -s 30

Write-Host "Assigning EMS and Mobility licenses..." -ForegroundColor Red
Set-MsolUser -userPrincipalName $userPrincipalName –UsageLocation US
Set-MsolUserLicense -userPrincipalName $userPrincipalName –AddLicenses “tenent:ENTERPRISEPACK”
Set-MsolUserLicense -userPrincipalName $userPrincipalName –AddLicenses “tenent:EMS”






## Do Exchange Online stuff
Write-Host "Connecting to Exchange Online..." -ForegroundColor Red
$ExchangeSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $credential -Authentication Basic -AllowRedirection

Import-PSSession $ExchangeSession

Write-Host "Turning on Litigation Hold..." -ForegroundColor Red
Set-Mailbox $userPrincipalName -LitigationHoldEnabled $true -Force

Write-Host "Disabling Clutter..." -ForegroundColor Red
Set-Clutter -Identity $userPrincipalName -Enable $false

Remove-PSSession $ExchangeSession







## Notify via email the user and the direct manager

## Email Subject 
$subject="$FirstName - Your account has been set up!" 
   
## Email Body Set Here 
$body =" 
$FirstName,

<p>Welcome to the team! Attached to this message is a quick-start guide detailing everything you need to know about accessing company resources. Below are the credentials you'll need to log in:

<p><u><b>Your logon information:</b></u><br>
<b>Username</b>: $userPrincipalName<br>
<b>Password</b>: $password

<p>Please review the contact information you see here, and reach out to the Service Desk if we've made any mistakes:

<p><u><b>Your contact information:</b></u><br>
<b>Name</b>: $FirstName $LastName<br>
<b>Title</b>: $usertitle<br>
<b>Department</b>: $department<br>
<b>Market</b>: $market<br>
<b>Mobile</b>: $cellphone<br>
<b>Office Phone</b>: $officephone<br>
<b>Extension</b>: $extension<br>
<b>Fax Number</b>: $fax

<p><u><b>Your direct manager:</b></u><br>
<b>Name</b>: $managername<br>
<b>Mobile</b>: $managermobile<br>
<b>Email</b>: $manageremail<br>

<p>If you have any questions, feel free to reach out to the Service Desk for assistance.

<p>Thank you, <br>

<p>Service Desk<br>
888-888-8888<br>
support@domain.com<br>

<p style=font-size:10px>This is a system-generated notice. Please do not respond.</p>  
</P>"


## Sends a mail message, CC'ing the user and their manager
Send-Mailmessage -smtpServer $smtpServer -from $from -to $emailaddress -cc "$manageremail", "$userPrincipalName" -subject $subject -body $body -Attachments ".\Docs\QuickStartGuide.pdf", ".\Docs\EmailSetup.pdf", ".\Docs\SurgicalCloudSetup.pdf" -bodyasHTML -priority High
Write-Host "The new hire message has been sent! You're done!" -ForegroundColor Red


Read-Host "Press any key to exit..."
exit