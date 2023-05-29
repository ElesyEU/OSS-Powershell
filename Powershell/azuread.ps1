Clear-Host

Import-Module AzureAD
Import-Module ActiveDirectory

# Connect to AzureAD

Connect-AzureAD

# Copy all groups that you are member off from Azure AD to the OU 'groups'.

$User = 's139965@ap.be'

$User_Id = (Get-AzureADUser -Filter "UserPrincipalName eq '$User'").ObjectId

$Azure_Groups = Get-AzureADUserMembership -ObjectId $User_Id | Get-AzureADGroup

# Copy all users in those groups to Active Directory, and put them in the relevant groups.

foreach ($Azure_Group in $Azure_Groups)
{
    $Azure_Group_Members = Get-AzureADGroupMember -ObjectId $AzureGroup.ObjectId

    foreach ($Azure_Group_Member in $Azure_Group_Members)
    {
        $Azure_User = Get-ADUser -Filter "UserPrincipalName -eq '$($Azure_Group_Member.UserPrincipalName)'"

        if (!$Azure_User)
        {
            New-ADUser -Name $Azure_user -Path "OU=users,OU=s139965,DC=poliformams,DC=local"
        }

        Add-ADGroupMember -Identity $Azure_Group -Members $Azure_User
    }
}