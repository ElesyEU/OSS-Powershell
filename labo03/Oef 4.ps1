clear-host
import-module AzureAD
$user = "s139965@ap.be"
Connect-AzureAD -AccountId $user
$currentUser = Get-AzureADUser -Filter "GivenName eq '$user'"
$userGroups = Get-AzureADUserMembership -ObjectId $user

#$os = $userGroups | Select-Object -Property DisplayName, Description | Where-Object DisplayName  -eq "22-23 OS Scripting - (AP-187945)"
#Get-AzureADGroupMember $os

$os = Get-AzureADGroup -Filter "DisplayName eq '22-23 OS Scripting - (AP-187945)'"
$users = Get-AzureADGroupMember -ObjectId $os.ObjectId | Select-Object -Property DisplayName
$users.count