## This script can be used to sign other Powershell scripts

Get-ChildItem cert:\CurrentUser\My -codesign

$choosecert = Read-Host -Prompt "Which certificate will you use to sign with? (choose 0, 1, 2, etc)"

$choosepath = Read-Host -Prompt "What is the exact path of the script you intend to sign? Include file path and file name"

Set-AuthenticodeSignature $choosepath @(Get-ChildItem cert:\CurrentUser\My -codesign)[$choosecert]