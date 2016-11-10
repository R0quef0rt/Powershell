## This script was compiled to simplify the process of resetting a password, and getting it to the employee. 
## It was last updated on 2/4/2016
## Created by Roquefort

## Load Active Directory Powershell module
Import-Module ActiveDirectory

## Load functions from other scripts

. ".\ChooseMobileCarrier.ps1"
Write-Host "Loaded ChooseMobileCarrier.ps1"
. ".\New-SWRandomPassword.ps1"
Write-Host "Loaded New-SWRandomPassword.ps1"


## Set SMTP Server variables. 
$smtpServer="mail.yourdomain.com" 
$from = "Service Desk <alerts@yourdomain.com>" 

## This uses the New-SWRandomPassword.ps1 script to generate a secure password, and store it as a variable
$newpw = New-SWRandomPassword -InputStrings abcdefghijklmnopqrstuvwxyz, ABCDEFGHIJKLMNOPQRSTUVWXYZ, 1234567890 -PasswordLength 12

## Prompt the user to send password over email or SMS
$title = "Send Method"
$message = "Will you send this message to email or SMS?"
$emailchannel = New-Object System.Management.Automation.Host.ChoiceDescription "&Email", `
    "Sends a brief message to an email address."
$smschannel = New-Object System.Management.Automation.Host.ChoiceDescription "&SMS", `
    "Sends a brief text message to a phone."
$options = [System.Management.Automation.Host.ChoiceDescription[]]($emailchannel, $smschannel)
$result = $host.ui.PromptForChoice($title, $message, $options, 0)
 
switch ($result)
    {
        0 {"The message will be sent by email."}
        1 {"The message will be sent by SMS."}
    }


## Looks at the answer to $result, and runs the build-email function if SMS
if ($result -eq "0"){
        $emailaddress = Read-Host -Prompt "Please enter the email address to send the password to"
    } elseif ($result -eq "1") {
        Write-Host "Building the email address..."
        $SMSPrefix = Read-Host -Prompt "Please enter the SMS phone number"
        . choose-carrier
        $emailaddress = $SMSPrefix + "@" + $SMSSuffix
}

Write-Host = "The new password will be sent to $emailaddress"

## This section allows a user to lookup the sAMAccountName for an employee
$searchuser = Read-Host -Prompt "Would you like to lookup a user's account? (y or n)"
if ($searchuser -eq "y") {
    $userlookup = Read-Host -Prompt "What is the first name of the employee you'd like to lookup?"
    Get-ADUser -LDAPFilter "(givenName=*$userlookup*)" | fl givenName,surname,sAMAccountName,userPrincipalName
    } elseif ($searchuser -eq "n") {
    Write-Host "You chose to skip the user lookup."
}

## Get the user account
$username = Read-Host "Please enter the sAMAccountName of the person whose account must be reset"

## Set AD password
Set-ADAccountPassword -Identity $username -Reset -NewPassword (ConvertTo-SecureString -AsPlainText "$newpw" -Force) -Confirm
Set-ADUser -Identity $username -ChangePasswordAtLogon $true

## Email Subject 
$subject="Your password has been reset" 
   
## Email Body Set Here 
$bodyemail =" 
Dear $username,

<p>Your company password has been reset to the following:

<p>$newpw

<p>To change the password to something that's easier to remember, you may follow one of these two options:

<p>1) If you have a company-issued workstation or laptop, press CTRL+ALT+DEL and choose 'Change a password', or;<br>
2) If you are on a personal device or company phone, you may navigate to <a href=https://account.activedirectory.windowsazure.com/ChangePassword.aspx>iforgot.domain.com</a>.

<p>Per the Employee Password Policy, your password must contain 12 characters, including a capital letter, a number, and a symbol. Passwords cannot contain consecutive, repeated characters (e.g., aaaaa11111) and cannot contain a string of characters that match previous passwords. Passwords may not contain all or part of a user's name or username.

<p>Note that if you have email on a cell phone, you will need to add the changed password to your phone's mail settings. On an iPhone, this can be found under 'Settings > Mail, Contacts, Calendars > Email'. Failure to update the password on your phone will halt email on it completely.

<p>As always, if you have any questions, feel free to reach out to the Service Desk for assistance.

<p>Thank you, <br>

<p>Service Desk<br>
888-888-8888<br>
<a href=https://www.domain.com/support>www.domain.com/support</a>

<p style=font-size:10px>This is a system-generated notice. Please do not respond.</p>  
</P>"

## SMS Body Set Here, Note You can use HTML, including Images. 
$bodysms ="Your new password is: [[ $newpw ]] (without brackets) To reset, navigate to <a href=https://sso.amerisurg.com/adfs/portal/updatepassword>iforgot.amerisurg.com</a>."

## Send short or long message, depending on if email or SMS
    if (($result) -eq "0") { 
        $body = $bodyemail
        } elseif (($result) -eq "1") {
        $body = $bodysms
    }


## Send Email Message 
Send-Mailmessage -smtpServer $smtpServer -from $from -to $emailaddress -subject $subject -body $body -bodyasHTML -priority High