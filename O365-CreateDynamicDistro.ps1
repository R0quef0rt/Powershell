## This script was created to ease the process of connecting with Exchange Online, and creating standard dynamic distribution groups.


## Creds used for connecting to Exchange Online
$UserCredential = Get-Credential

$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $UserCredential -Authentication Basic -AllowRedirection

Import-PSSession $Session


## Fill in this section to customize the script

$city = "Houston"
$stateshort = "TX"
$statelong = "Texas"
$department = "Accountants"
$department1 = "Billers"
$others = "Others"
$domain = "domain.com"

$scope = "All"
$scope1 = "Users"

# This section creates 4 new dynamic distribution groups in Office 365. The groups are filtered to the "City" and "State" level, as well as "Department".

New-DynamicDistributionGroup -Name "$city $scope" -PrimarySmtpAddress $cityEmployees@$domain -RecipientFilter {(RecipientType -eq 'UserMailbox') -and (City -eq $city) -and (StateOrProvince -eq $stateshort)}
New-DynamicDistributionGroup -Name "$city $department" -PrimarySmtpAddress $city$departments@$domain -RecipientFilter {(RecipientType -eq 'UserMailbox') -and (City -eq $city) -and (StateOrProvince -eq $stateshort) -and (Department -eq $department)}
New-DynamicDistributionGroup -Name "$city $department1" -PrimarySmtpAddress $cityPRNs@$domain -RecipientFilter {(RecipientType -eq 'UserMailbox') -and (City -eq $city) -and (StateOrProvince -eq $stateshort) -and (Department -eq $department1)}
New-DynamicDistributionGroup -Name "$city $scope1" -PrimarySmtpAddress $cityOffices@$domain -RecipientFilter {(RecipientType -eq 'UserMailbox') -and (City -eq $city) -and (StateOrProvince -eq $stateshort)  -and (Department -notlike $department -or Department -notlike $department1)}

# This section creates a state-wide dynamic distribution group. It is filtered by the "State" field in AD.

New-DynamicDistributionGroup -Name "$statelong $scope" -PrimarySmtpAddress $statelong$scope@$domain -RecipientFilter {(RecipientType -eq 'UserMailbox') -and (StateOrProvince -eq $stateshort)}
New-DynamicDistributionGroup -Name "$statelong $department" -PrimarySmtpAddress $statelongs$department@$domain -RecipientFilter {(RecipientType -eq 'UserMailbox') -and (StateOrProvince -eq $stateshort) -and (Department -eq $department)}
New-DynamicDistributionGroup -Name "$statelong $department1" -PrimarySmtpAddress $statelong$department1@$domain -RecipientFilter {(RecipientType -eq 'UserMailbox') -and (StateOrProvince -eq $stateshort) -and (Department -eq $department1)}
New-DynamicDistributionGroup -Name "$statelong $others" -PrimarySmtpAddress $statelong$others@$domain -RecipientFilter {(RecipientType -eq 'UserMailbox') -and (StateOrProvince -eq $stateshort) -and (Department -notlike $department -or Department -notlike $department1)}

# This section creates an organization-wide distribution group. It is not filtered by any field other than "Department" in AD.

New-DynamicDistributionGroup -Name "$scope $scope1" -PrimarySmtpAddress $scope$scope1@$domain -RecipientFilter {(RecipientType -eq 'UserMailbox')}
New-DynamicDistributionGroup -Name "$scope $department" -PrimarySmtpAddress $scope$department@$domain -RecipientFilter {(RecipientType -eq 'UserMailbox') -and (Department -eq $department)}
New-DynamicDistributionGroup -Name "$scope $department1" -PrimarySmtpAddress $scope$department1@$domain -RecipientFilter {(RecipientType -eq 'UserMailbox') -and (Department -eq $department1)}
New-DynamicDistributionGroup -Name "$scope $others" -PrimarySmtpAddress $scope$others@$domain -RecipientFilter {(RecipientType -eq 'UserMailbox') -and (Department -notlike $department -or Department -notlike $department1)}

Remove-PSSession $Session