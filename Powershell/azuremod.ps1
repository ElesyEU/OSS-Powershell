Clear-Host

Import-Module AzureAD

# Connect to AzureAD.

Connect-AzureAD

# Copy the groups from Azure of which you are member.

$User = 's139965@ap.be'
$User_Id = (Get-AzureADUser -Filter "UserPrincipalName eq '$User'").ObjectId
$Azure_Groups = Get-AzureADUserMembership -ObjectId $User_Id | Get-AzureADGroup
$Azure_Group_Pattern = "22-23 *"

# Connect to the local Active Directory.

Enter-PSSession -ComputerName localhost
Import-Module ActiveDirectory -Force

# Define Global variables.

$OU_Input = Read-Host -Prompt (Write-Host "Which OU would you like to create for further use within this script?`n" -ForegroundColor Yellow)
$OU_True_Input = Get-ADOrganizationalUnit -Filter "Name -eq `"$OU_Input`""
$OU_True_Student_Number = Get-ADOrganizationalUnit -Filter "Name -eq 's139965'"
$OU_True_users = Get-ADOrganizationalUnit -Filter "Name -eq 'users'"
$OU_True_groups = Get-ADOrganizationalUnit -Filter "Name -eq 'groups'"
$Student_Number = 's139965'
$Domain = (Get-ADDomain).DistinguishedName
$Domain_Print = (Get-ADDomain).DNSRoot

# Check if a given OU already exists in the current domain, if not create it.

if (!$OU_True_Input)
{
    New-ADOrganizationalUnit -Name $OU_Input -Path "$Domain" -ProtectedFromAccidentalDeletion $false
    Write-Host "The OU <$OU_Input> was created in the domain <$Domain_Print>" -ForegroundColor Green
}
elseif ($OU_True_Input)
{
    Write-Host "The OU <$OU_Input> already exists in the domain <$Domain_Print>" -ForegroundColor Red
}

# Check if the OU 's139965' already exists in the above OU, if not create it.

if (!$OU_True_Student_number)
{
    New-ADOrganizationalUnit -Name $Student_Number -Path "OU=$OU_Input,$Domain" -ProtectedFromAccidentalDeletion $false
    Write-Host "The OU <$Student_Number> was created in the OU <$OU_Input>" -ForegroundColor Green
}
elseif ($OU_True_Student_Number)
{
    Write-Host "The OU <$Student_Number> already exists in the OU <$OU_Input>" -ForegroundColor Red
}

# Check if the OU's 'groups' and 'users' already exist in the above OU, if not create them.

if (!$OU_True_users)
{
    New-ADOrganizationalUnit -Name 'users' -Path "OU=$Student_Number,OU=$OU_Input,$Domain" -ProtectedFromAccidentalDeletion $false
    Write-Host "The OU <users> was created in the OU <$Student_Number>" -ForegroundColor Green
}
elseif ($OU_True_users)
{
    Write-Host "The OU <users> already exists in the OU <$Student_Number>" -ForegroundColor Red
}

if (!$OU_True_groups)
{
    New-ADOrganizationalUnit -Name 'groups' -Path "OU=$Student_Number,OU=$OU_Input,$Domain" -ProtectedFromAccidentalDeletion $false
    Write-Host "The OU <groups> was created in the OU <$Student_Number>" -ForegroundColor Green
}
elseif ($OU_True_groups)
{
    Write-Host "The OU <groups> already exists in the OU <$Student_Number>" -ForegroundColor Red
}

# Copy all groups that you are member off from Azure AD to the OU 'groups'.
# Copy all users that are member of those groups from Azure AD to the OU 'users'.
# Copy all users that are member of those groups to their respective groups in the OU 'groups'.

foreach ($Azure_Group in $Azure_Groups)
{
    if ($Azure_Group.DisplayName -like $Azure_Group_Pattern)
    {
        $AD_Group = $Azure_Group.DisplayName.Substring(6)
        $AD_Group = $AD_Group.Substring(0, $AD_Group.Length - 14)
        $AD_True_Group = Get-ADGroup -Filter "Name -eq `"$AD_Group`""
        if (!$AD_True_Group)
        {
            New-ADGroup -Name $AD_Group -GroupScope Global -Path "OU=groups,OU=$Student_Number,OU=$OU_Input,$Domain"
            Write-Host "The group <$AD_Group> was created in the OU <groups>" -ForegroundColor Green
        }
        elseif ($AD_True_Group)
        {
            Write-Host "The group <$AD_Group> already exists in the OU <groups>" -ForegroundColor Red
        }

        # Copy all users in those groups to Active Directory, and put them in the relevant groups.

        $Azure_Group_Members = Get-AzureADGroupMember -ObjectId $Azure_Group.ObjectId
        $AD_Group_Members = Get-ADGroupMember -Identity $AD_Group
        $AD_User_In_AD_Group = $AD_Group_Members | Where-Object {$_.SamAccountName -eq $Azure_Group_Member.UserPrincipalName}

        foreach ($Azure_Group_Member in $Azure_Group_Members)
        {
            $AD_User_Exists = Get-ADUser -Filter "UserPrincipalName -eq `"$($Azure_Group_Member.UserPrincipalName)`""
            $AD_User_In_AD_Group = $AD_Group_Members | Where-Object {$_.SamAccountName -eq $Azure_Group_Member.UserPrincipalName}

            if (!$AD_User_Exists -and $Azure_Group_Member.UserPrincipalName.StartsWith('s') -and $Azure_Group_Member.UserPrincipalName.EndsWith('@ap.be'))
            {
                New-ADUser -Name $Azure_Group_Member.UserPrincipalName -UserPrincipalName $Azure_Group_Member.UserPrincipalName -Path "OU=users,OU=$Student_Number,OU=$OU_Input,$Domain"
                Write-Host "User <$($Azure_Group_Member.UserPrincipalName)> was created in the OU <users>'" -ForegroundColor Green
            }
            elseif ($AD_User_Exists -and $Azure_Group_Member.UserPrincipalName.StartsWith('s') -and $Azure_Group_Member.UserPrincipalName.EndsWith('@ap.be'))
            {
                Write-Host "User <$($Azure_Group_Member.UserPrincipalName)> already exists in the OU <users>" -ForegroundColor Red
            }

            if (!$AD_User_In_AD_Group -and $Azure_Group_Member.UserPrincipalName.StartsWith('s') -and $Azure_Group_Member.UserPrincipalName.EndsWith('@ap.be')) 
                {
                Add-ADGroupMember -Identity $AD_Group -Members $Azure_Group_Member.UserPrincipalName
                Write-Host "User <$($Azure_Group_Member.UserPrincipalName)> was added to the group <$AD_Group>" -ForegroundColor Green
                } 
            elseif ($AD_User_In_AD_Group -and $Azure_Group_Member.UserPrincipalName.StartsWith('s') -and $Azure_Group_Member.UserPrincipalName.EndsWith('@ap.be'))
            {
                Write-Host "User <$($Azure_Group_Member.UserPrincipalName)> is already a member of the group <$AD_Group>" -ForegroundColor Red
            }
        }
    }
}