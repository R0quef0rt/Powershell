# Powershell


## Add this value to the registry via Powershell in order to add a right-click "Run as administrator" powershell context
New-Item -Path "Registry::HKEY_CLASSES_ROOT\Microsoft.PowershellScript.1\Shell\runas\command" ` -Force -Name '' -Value '"c:\windows\system32\windowspowershell\v1.0\powershell.exe" -noexit "%1"'
 
## Several of these scripts require the Microsoft Online Services Sign-In Assistant
https://www.microsoft.com/en-us/download/details.aspx?id=41950
 
## Several more require the Azure Active Directory Module for MS Powershell
http://go.microsoft.com/fwlink/p/?linkid=236297