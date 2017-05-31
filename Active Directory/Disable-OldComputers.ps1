## This script will moved inactive computer accounts (90 days) to the "Example" OU, and disable them.

## Set these variables
$targetOU = "OU=Example,DC=domain,DC=com"


import-module ActiveDirectory
 
Search-ADAccount -ComputersOnly -AccountInactive -TimeSpan 0.00:00:00 | where Enabled -eq $true | where Name -notlike CL* | ForEach-Object {
        $olddesc = (Get-ADComputer -Identity $_ -Prop description).Description
        disable-adaccount $_ 
        set-adcomputer $_ -Description "Account disabled $(Get-Date -format "yyyy-MM-dd") by System. $olddesc"         
        move-adobject $_ -targetpath "$targetOU" 
        } 
 
Search-ADAccount -ComputersOnly -AccountInactive -TimeSpan 90.00:00:00 | where Enabled -eq $true | ForEach-Object {
        $olddesc = (Get-ADComputer -Identity $_ -Prop description).Description
        disable-adaccount $_ 
        set-adcomputer $_ -Description "Account disabled $(Get-Date -format "yyyy-MM-dd") by System. $olddesc"         
        move-adobject $_ -targetpath "$targetOU" 
        }
