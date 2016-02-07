############# Many of the sleep timers could be fixed by properly targetting a DC

##### This script requires the Microsoft Online Services Sign-In Assistant, as well as the Azure Active Directory Module for Powershell


#### could be improved by running Azure commands on remote machine, rather than relying upon locally installed components to run. Invoke-Command would be better.

## Set servers which this script can connect to
$domaincontroller = "server01.domain.local"
$exchangeserver = "server02.domain.local"
$azureserver = "server03.domain.local"

## Set SMTP Server variables
$smtpServer="relay.domain.com" 
$from = "Service Desk <alerts@domain.com>" 

## Credentials for Azure
Write-Host "Which credentials will you use for Azure? This probably isn't your admin account" -ForegroundColor Red
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
$homefolder = "\\domain.local\HomeFolders\$FirstName$LastName"
$usertitle = Read-Host -Prompt "What is the employee's title" 

## These options could be more dynamic

$LogonDomain = "domain.com"
$userPrincipalName = "$FirstName.$LastName@$logonDomain"
$department = Read-Host -Prompt "Department"
$company = Read-Host -Prompt "Company"

## Prompt user to choose a market

Write-Host "Please choose the user's primary market of operation" -ForegroundColor Red
$title = "Send Method"
$message = "Set primary market"
$houstontx = New-Object System.Management.Automation.Host.ChoiceDescription "&Houston, TX", `
    "Houston, TX"
$dallastx = New-Object System.Management.Automation.Host.ChoiceDescription "&Dallas, TX", `
    "Dallas, TX"
$beaumonttx = New-Object System.Management.Automation.Host.ChoiceDescription "&Beaumont, TX", `
    "Beaumont, TX"
$austintx = New-Object System.Management.Automation.Host.ChoiceDescription "&Austin, TX", `
    "Austin, TX"
$corpuschristitx = New-Object System.Management.Automation.Host.ChoiceDescription "&Corpus Christi, TX", `
    "Corpus Christi, TX"
$sanantoniotx = New-Object System.Management.Automation.Host.ChoiceDescription "&San Antonio, TX", `
    "San Antonio, TX"
$options = [System.Management.Automation.Host.ChoiceDescription[]]($houstontx, $dallastx, $beaumonttx, $austintx, $corpuschristitx, $sanantoniotx)
$result = $host.ui.PromptForChoice($title, $message, $options, 0)
 
switch ($result)
    {
        0 {"You set Houston, TX."}
        1 {"You set Dallas, TX."}
        2 {"You set Beaumont, TX."}
        3 {"You set Austin, TX."}
        4 {"You set Corpus Christi, TX."}
        5 {"You set San Antonio, TX."}
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
    } elseif ($result -eq "3") {
    $market = "Austin, TX"
    $city = "Austin"
    $state = "TX"
    } elseif ($result -eq "4") {
    $market = "Corpus Christi, TX"
    $city = "Corpus Christi"
    $state = "TX"
    } elseif ($result -eq "5") {
    $market = "San Antonio, TX"
    $city = "San Antonio"
    $state = "TX"
    } else { 
}


$managerlookup = Read-Host -Prompt "Who does this employee report to? Searching by first and last name works best"

$otheruserlookup = Read-Host -Prompt "Who should we copy security permissions from? Searching by first and last name works best"

Write-Host "Where should we send an email notification to? The direct manager will be automatically CC'd." -ForegroundColor Red
$emailaddress = Read-Host -Prompt "Personal Email Address"








## This generates a secure password, and store it as a variable

Add-Type -AssemblyName System.Web
$password = [System.Web.Security.Membership]::GeneratePassword(12,5)






## Connect to Remote Powershell on the Exchange 2016 Hybrid server

Write-Host "Connecting to the local Exchange 2016 Hybrid environment..." -ForegroundColor Red
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://$exchangeserver/PowerShell/ -Authentication Kerberos
Import-PSSession $Session

## Create Mailbox

Write-Host "Creating mailbox..." -ForegroundColor Red
New-RemoteMailbox -FirstName $FirstName -LastName $LastName -Initials $Initials -Name "$FirstName $LastName" -DisplayName "$FirstName $LastName" -OnPremisesOrganizationalUnit domain.local/USERS/Users -Password (ConvertTo-SecureString -AsPlainText "$password" -Force) -UserPrincipalName "$userPrincipalName" -Archive -DomainController $domaincontroller
Remove-PSSession $Session






## Do AD Stuff.

Write-Host "Mailbox created. Connecting to the local Active Directory environment..." -ForegroundColor Red
Import-Module ActiveDirectory
Write-Host "Waiting for Active Directory to update with the newly-created user account..." -ForegroundColor Red
Start-Sleep -s 30
$sAMAccountName = Get-ADUser -LDAPFilter "(userPrincipalName=$userPrincipalName)" | foreach { $_.samaccountname }




##choose manager

$manager = Get-ADUser -LDAPFilter "(name=$managerlookup)" | foreach { $_.distinguishedname }
$manageremail = Get-ADUser  -Properties mail | select mail | foreach { $_.mail }
$managermobile = Get-ADUser -LDAPFilter "(name=$managerlookup)" -Properties MobilePhone| select mobilephone | foreach { $_.mobilephone }
$managername = Get-ADUser -LDAPFilter "(name=$managerlookup)" | foreach { $_.name }
Write-Host "You've selected $managername as the manager" -ForegroundColor Red

## Set AD Attributes
Set-ADUser -Identity $sAMAccountName -Office $market -OfficePhone "$officephone $extension" -MobilePhone $cellphone -Fax $fax -HomeDrive "Q:" -HomeDirectory "$homefolder" -City $city -State $state -Company $company -Department $department -Title $usertitle -Manager $manager

## Set security groups
Write-Host "Setting security permissions..." -ForegroundColor Red

$otherusersam = Get-ADUser -LDAPFilter "(name=$otheruserlookup)" | foreach { $_.samaccountname }
Write-Host "You chose to copy permissions from $otheruserlookup..." -ForegroundColor Red

Get-ADUser -Identity $otherusersam -Properties memberof | Select-Object -ExpandProperty memberof | Add-ADGroupMember -Members $sAMAccountName -PassThru | Select-Object -Property SamAccountName





## Runs a dirsync to move user into Azure
schtasks.exe /Run /S "$azureserver" /TN "Azure AD Sync Scheduler" /I
Write-Host "Waiting 60 seconds for local Active Directory to sync with Microsoft Azure..." -ForegroundColor Red
Start-Sleep -s 60



## Connect to $azureserver. This is required in order to run commands against Azure without the need to install components locally.

Write-Host "Signing in to Microsoft Azure..." -ForegroundColor Red

Import-Module MsOnline
Connect-MsolService -Credential $credential

Start-Sleep -s 30

Write-Host "Assigning EMS and Mobility licenses..." -ForegroundColor Red
Set-MsolUser -userPrincipalName $userPrincipalName –UsageLocation US
Set-MsolUserLicense -userPrincipalName $userPrincipalName –AddLicenses “aaapro:ENTERPRISEPACK”
Set-MsolUserLicense -userPrincipalName $userPrincipalName –AddLicenses “aaapro:EMS”






## Do Exchange Online stuff
Write-Host "Connecting to Exchange Online..." -ForegroundColor Red
$ExchangeSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $credential -Authentication Basic -AllowRedirection

Import-PSSession $ExchangeSession

Write-Host "Turning on Litigation Hold..." -ForegroundColor Red
Set-Mailbox $userPrincipalName -LitigationHoldEnabled $true -Force

Remove-PSSession $ExchangeSession







## Notify via email the user and the direct manager

## Email Subject 
$subject="$FirstName - Your company account has been set up!" 
   
## Email Body Set Here 
$body =" 
$FirstName,

<p>Welcome to the team! Attached to this message is a quick-start guide detailing everything you need to know about accessing company resources at <company>. Below are the credentials you'll need to log in:

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

<p>To change your password to something that's easier to remember, you may follow one of these two options:

<p>1) If you have a company-issued workstation or laptop, press CTRL+ALT+DEL and choose 'Change a password', or;<br>
2) If you are on a personal device or company phone, you may navigate to <a href=https://account.activedirectory.windowsazure.com/ChangePassword.aspx>iforgot.domain.com</a>.

<p>Per the Employee Password Policy, your password must contain 12 characters, including a capital letter, a number, and a symbol. Passwords cannot contain consecutive, repeated characters (e.g., aaaaa11111) and cannot contain a string of characters that match previous passwords. Passwords may not contain all or part of a user's name or username.

<p>If you have any questions, feel free to reach out to the Service Desk for assistance.

<p>Thank you, <br>

<p>Service Desk<br>
832-804-8795<br>
support@domain.com<br>
<a href=https://www.domain.com/support>www.domain.com/support</a>

<p style=font-size:10px>This is a system-generated notice. Please do not respond.</p>  
</P>"


## Sends a mail message, CC'ing the user and their manager
Send-Mailmessage -smtpServer $smtpServer -from $from -to $emailaddress -cc "$manageremail", "$userPrincipalName" -subject $subject -body $body -Attachments "\\domain.local\all\Maintenance\Deployment\Scripts\NewHireDocument.pdf", "\\domain.local\all\Maintenance\Deployment\Scripts\SettingASPEmailOnYourPersonalPhone.pdf" -bodyasHTML -priority High
Write-Host "The new hire message has been sent! You're done!" -ForegroundColor Red