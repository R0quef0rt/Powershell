################################################################################################################# 
#  
# Version 1.3 April 2015 
# Robert Pearman (WSSMB MVP) 
# TitleRequired.com 
# Script to Automated Email Reminders when Users Passwords due to Expire. 
# 
# Requires: Windows PowerShell Module for Active Directory 
# 
# For assistance and ideas, visit the TechNet Gallery Q&A Page. http://gallery.technet.microsoft.com/Password-Expiry-Email-177c3e27/view/Discussions#content 
# 
################################################################################################################## 
# Please Configure the following variables.... 
$smtpServer="server.domain.com" 
$expireindays = 30
$from = "Service Desk <alerts@domain.com>" 
$logging = "Enabled" # Set to Disabled to Disable Logging 
$logFile = "c:\Scripts\pwdlog.csv" # ie. c:\mylog.csv 
$testing = "Disabled" # Set to Disabled to Email Users 
$testRecipient = "" 
$date = Get-Date -format ddMMyyyy 
# 
################################################################################################################### 
 
# Check Logging Settings 
if (($logging) -eq "Enabled") 
{ 
    # Test Log File Path 
    $logfilePath = (Test-Path $logFile)
    if (($logFilePath) -ne "True") 
    { 
        # Create CSV File and Headers 
        New-Item $logfile -ItemType File 
        Add-Content $logfile "Date,Name,EmailAddress,DaystoExpire,ExpiresOn" 
    } 
} # End Logging Check 
 
# Get Users From AD who are Enabled, Passwords Expire and are Not Currently Expired 
Import-Module ActiveDirectory 
$users = get-aduser -filter * -properties Name, PasswordNeverExpires, PasswordExpired, PasswordLastSet, EmailAddress |where {$_.Enabled -eq "True"} | where { $_.PasswordNeverExpires -eq $false } | where { $_.passwordexpired -eq $false } 
$DefaultmaxPasswordAge = (Get-ADDefaultDomainPasswordPolicy).MaxPasswordAge 
 
# Process Each User for Password Expiry 
foreach ($user in $users) 
{ 
    $Name = $user.Name 
    $emailaddress = $user.emailaddress 
    $passwordSetDate = $user.PasswordLastSet 
    $PasswordPol = (Get-AduserResultantPasswordPolicy $user) 
    # Check for Fine Grained Password 
    if (($PasswordPol) -ne $null) 
    { 
        $maxPasswordAge = ($PasswordPol).MaxPasswordAge 
    } 
    else 
    { 
        # No FGP set to Domain Default 
        $maxPasswordAge = $DefaultmaxPasswordAge 
    } 
 
   
    $expireson = $passwordsetdate + $maxPasswordAge 
    $today = (get-date) 
    $daystoexpire = (New-TimeSpan -Start $today -End $Expireson).Days 
         
    # Set Greeting based on Number of Days to Expiry. 
 
    # Check Number of Days to Expiry 
    $messageDays = $daystoexpire 
 
    if (($messageDays) -ge "1") 
    { 
        $messageDays = "in " + "$daystoexpire" + " days" 
    } 
    else 
    { 
        $messageDays = "today." 
    } 
 
    # Email Subject Set Here 
    $subject="Your password will expire $messageDays" 
   
    # Email Body Set Here, Note You can use HTML, including Images. 
    $body =" 
    Hey $name,
     
    <p> Your company password is set to expire $messageDays. If it does, you'll be locked-out of your computer, email, and applications. To prevent this from happening, please reset your password in one of these two ways:

    <p>1) If you have a company-issued workstation or laptop, press CTRL+ALT+DEL and choose 'Change a password'.
	
	<p>Per the Employee Password Policy, your password must contain 400 characters, including 14 capital letters, 24 numbers, and at least 7 symbols (@,#,!,?, etc.)
    
	<p>Note that if you have email on a cell phone, you will need to add the changed password to your phone's mail settings. On an iPhone, this can be found under 'Settings > Mail, Contacts, Calendars > Email'. Failure to update the password on your phone will halt email on it completely.
	
	<p>As always, if you have any questions, feel free to reach out to the Service Desk for assistance.
	
	<p>Thank you, <br>
    
    <p>Service Desk<br>
	888-888-888<br>
    
    <p style=font-size:10px>This is a system-generated notice. Please do not respond.</p>  
    </P>" 
 
    
    # If Testing Is Enabled - Email Administrator 
    if (($testing) -eq "Enabled") 
    { 
        $emailaddress = $testRecipient 
    } # End Testing 
 
    # If a user has no email address listed 
    if (($emailaddress) -eq $null) 
    { 
        $emailaddress = $testRecipient     
    }# End No Valid Email 
 
    # Send Email Message 
    if (($daystoexpire -ge "0") -and ($daystoexpire -lt $expireindays)) 
    { 
         # If Logging is Enabled Log Details 
        if (($logging) -eq "Enabled") 
        { 
            Add-Content $logfile "$date,$Name,$emailaddress,$daystoExpire,$expireson"  
        } 
        # Send Email Message 
        Send-Mailmessage -smtpServer $smtpServer -from $from -to $emailaddress -subject $subject -body $body -bodyasHTML -priority High   
 
    } # End Send Message 
     
} # End User Processing 
 
 
 
# End