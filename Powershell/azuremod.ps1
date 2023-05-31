Clear-Host

Import-Module AzureAD
Import-Module ActiveDirectory

# Define global variables.

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
    Write-Host "`nThe OU <$OU_Input> was created in the domain <$Domain_Print>`n" -ForegroundColor Green
}
elseif ($OU_True_Input)
{
    Write-Host "`nThe OU <$OU_Input> already exists in the domain <$Domain_Print>`n" -ForegroundColor Red
}

# Check if the OU 's139965' already exists in the above OU, if not create it.

if (!$OU_True_Student_number)
{
    New-ADOrganizationalUnit -Name $Student_Number -Path "OU=$OU_Input,$Domain" -ProtectedFromAccidentalDeletion $false
    Write-Host "`nThe OU <$Student_Number> was created in the OU <$OU_Input>`n" -ForegroundColor Green
}
elseif ($OU_True_Student_Number)
{
    Write-Host "`nThe OU <$Student_Number> already exists in the OU <$OU_Input>`n" -ForegroundColor Red
}

# Check if the OU's 'groups' and 'users' already exist in the above OU, if not create them.

if (!$OU_True_users)
{
    New-ADOrganizationalUnit -Name 'users' -Path "OU=$Student_Number,OU=$OU_Input,$Domain" -ProtectedFromAccidentalDeletion $false
    Write-Host "`nThe OU <users> was created in the OU <$Student_Number>`n" -ForegroundColor Green
}
elseif ($OU_True_users)
{
    Write-Host "`nThe OU <users> already exists in the OU <$Student_Number>`n" -ForegroundColor Red
}

if (!$OU_True_groups)
{
    New-ADOrganizationalUnit -Name 'groups' -Path "OU=$Student_Number,OU=$OU_Input,$Domain" -ProtectedFromAccidentalDeletion $false
    Write-Host "`nThe OU <groups> was created in the OU <$Student_Number>`n" -ForegroundColor Green
}
elseif ($OU_True_groups)
{
    Write-Host "`nThe OU <groups> already exists in the OU <$Student_Number>`n" -ForegroundColor Red
}

# Connect to AzureAD.

Connect-AzureAD

# Define local variables.

$User = 's139965@ap.be'
$User_Id = (Get-AzureADUser -Filter "UserPrincipalName eq '$User'").ObjectId
$Azure_Groups = Get-AzureADUserMembership -ObjectId $User_Id | Get-AzureADGroup
$Azure_Group_Pattern = "22-23 *"

# Copy all groups that you are member off from Azure AD to the OU 'groups'.

foreach ($Azure_Group in $Azure_Groups)
{
    if ($Azure_Group.DisplayName -like $Azure_Group_Pattern)
    {
        $AD_Group = $Azure_Group.DisplayName.Substring(6)
        $AD_Group = $AD_Group.Substring(0, $AD_Group.Length - 14)
        $AD_True_Group = Get-ADGroup -Filter "Name -eq `"$AD_Group`""
        if (!$AD_True_Group)
        {
            New-ADGroup -Name "$AD_Group" -GroupScope Global -Path "OU=groups,OU=$Student_Number,OU=$OU_Input,$Domain"
            Write-Host "The group '$AD_Group' was created in the OU 'groups" -ForegroundColor Green
        }
        elseif ($AD_True_Group)
        {
            Write-Host "The group '$AD_Group' already exists in the OU 'groups': " -ForegroundColor Red
        }
    }
}