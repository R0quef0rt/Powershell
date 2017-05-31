## Sets the computer to use the specified DC. Important to fix issues with "sync" during the employment script.
nltest /Server:$env:computername /SC_RESET:DOMAIN.com\server

## Sets the current working directory. Important because other scripts a built to run from the same directory as this launcher.
$ScriptDir = Split-Path $script:MyInvocation.MyCommand.Path
Write-Host "Current script directory is $ScriptDir"
Set-Location "$ScriptDir"

## Launch an interface for choosing other scripts
$launchertitle = "Script Launch Tool"
$launchermessage = "Which script will you run?"
$scriptsendpassword = New-Object System.Management.Automation.Host.ChoiceDescription "&Reset Password", `
    "Resets a password, then emails the user."
$scriptnewhire = New-Object System.Management.Automation.Host.ChoiceDescription "&New Hire", `
    "Sets up all domain-integrated aspects of a new user account."
$scriptsecuritycheck = New-Object System.Management.Automation.Host.ChoiceDescription "&AD Security Audit", `
    "Checks AD for common security issues."
$scriptdynamicdistro = New-Object System.Management.Automation.Host.ChoiceDescription "&Create Dynamic Distribution Group", `
    "Checks AD for common security issues."
$scriptexportusers = New-Object System.Management.Automation.Host.ChoiceDescription "&Export All AD Users", `
    "Exports all AD users to CSV."
$scriptsignpowershell = New-Object System.Management.Automation.Host.ChoiceDescription "&Sign Powershell Script", `
    "Signs a Powershell script."
$scriptsyncazure = New-Object System.Management.Automation.Host.ChoiceDescription "&Microsoft Azure Sync", `
    "Syncs the AAD server with MS Azure."
$scriptdistromembers = New-Object System.Management.Automation.Host.ChoiceDescription "&List Dynamic Distribution Group Members", `
    "Lists all users in an Exchange Dynamic Distribution List."
$scriptdisablecomputers = New-Object System.Management.Automation.Host.ChoiceDescription "&Disable Old Computers (90 days)", `
    "Disables and moves all stale computer accounts to the ASADISABLED OU."
$launcheroptions = [System.Management.Automation.Host.ChoiceDescription[]]($scriptsendpassword, $scriptnewhire, $scriptsecuritycheck, $scriptdynamicdistro, $scriptexportusers, $scriptsignpowershell, $scriptsyncazure, $scriptdistromembers, $scriptdisablecomputers)
$launcherresult = $host.ui.PromptForChoice($launchertitle, $launchermessage, $launcheroptions, 0)
 
switch ($launcherresult)
    {
        0 {Invoke-Expression .\SendNewPassword.ps1}
        1 {Invoke-Expression .\New-Employee.ps1}
        2 {Invoke-Expression .\AD-CommonSecurityIssues.ps1}
        3 {Invoke-Expression .\O365-CreateDynamicDistro.ps1}
        4 {Invoke-Expression .\ExportADUsers.ps1}
        5 {Invoke-Expression .\SignOtherScripts.ps1}
        6 {Invoke-Expression .\RunAzureSync.ps1}
        7 {Invoke-Expression .\ListDistroGroupUsers.ps1}
        8 {Invoke-Expression .\ActiveDirectory\Move-OldComputers.ps1}
}