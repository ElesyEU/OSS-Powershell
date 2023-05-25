clear-host
import-module AzureAD
$user = "s139965@ap.be"
Connect-AzureAD -AccountId $user
$currentUser = Get-AzureADUser -Filter "GivenName eq 'Dries'"
$currentUser | Format-List *