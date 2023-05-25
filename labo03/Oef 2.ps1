clear-host
import-module AzureAD
$user = "s139965@ap.be"
Connect-AzureAD -AccountId $user
$currentUser = Get-AzureADUser -Filter "UserPrincipalName eq 's139965@ap.be'"
$currentUser | Format-List *