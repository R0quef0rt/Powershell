## This script checks Active Directory for several common issues that severely compromise the security of an account.
## These scripts were originally sourced here: https://www.reddit.com/r/sysadmin/comments/3y0pad/some_ad_checks_you_should_be_running_on_a_regular/
## This script was created by R0quef0rt, 2015



## 1. Check for accounts that don't have password expiry set
Get-ADUser -Filter 'useraccountcontrol -band 65536' -Properties useraccountcontrol | export-csv c:\reports\U-DONT_EXPIRE_PASSWORD.csv

## 2. Check for accounts that have no password requirement
Get-ADUser -Filter 'useraccountcontrol -band 32' -Properties useraccountcontrol | export-csv c:\reports\U-PASSWD_NOTREQD.csv

## 3. Accounts that have the password stored in a reversibly encrypted format
Get-ADUser -Filter 'useraccountcontrol -band 128' -Properties useraccountcontrol | export-csv c:\reports\U-ENCRYPTED_TEXT_PWD_ALLOWED.csv

## 4. List users that are trusted for Kerberos delegation
Get-ADUser -Filter 'useraccountcontrol -band 524288' -Properties useraccountcontrol | export-csv c:\reports\U-TRUSTED_FOR_DELEGATION.csv

## 5. List accounts that don't require pre-authentication
Get-ADUser -Filter 'useraccountcontrol -band 4194304' -Properties useraccountcontrol | export-csv c:\reports\U-DONT_REQUIRE_PREAUTH.csv

## 6. List accounts that have credentials encrypted with DES
Get-ADUser -Filter 'useraccountcontrol -band 2097152' -Properties useraccountcontrol | export-csv c:\reports\U-USE_DES_KEY_ONLY.csv