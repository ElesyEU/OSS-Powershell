Clear-Host

Import-Module AzureAD

# Check if a given OU already exists in the current domain, if not create it.

$OU_Input = Read-Host -Prompt (Write-Host "Which OU would you like to create for further use within this script?`n" -ForegroundColor Yellow)
$OU_True_OS_Scripting_23 = Get-ADOrganizationalUnit -Filter "Name -eq 'OS Scripting 23'"
$OU_True_Student_Number = Get-ADOrganizationalUnit -Filter "Name -eq 's139965'"
$OU_True_users = Get-ADOrganizationalUnit -Filter "Name -eq 'users'"
$OU_True_groups = Get-ADOrganizationalUnit -Filter "Name -eq 'groups'"
$Domain = (Get-ADDomain).DistinguishedName
$Domain_Print = (Get-ADDomain).DNSRoot

if (!$OU_True_OS_Scripting_23)
{
    New-ADOrganizationalUnit -Name 'OS Scripting 23' -Path "$Domain"
    Write-Host "`nThe OU <OS Scripting 23> was created in the domain <$Domain_Print>`n" -ForegroundColor Green
}
elseif ($OU_True_OS_Scripting_23)
{
    Write-Host "`nThe OU <OS Scripting 23> already exists in the domain <$Domain_Print>`n" -ForegroundColor Red
}

# Check if the OU 's139965' already exists in the above OU, if not create it.

if (!$OU_True_Student_number)
{
    New-ADOrganizationalUnit -Name 's139965' -Path "OU=$OU_Input,$Domain"
    Write-Host "`nThe OU <s139965> was created in the OU <$OU_Input>`n" -ForegroundColor Green
}
elseif ($OU_True_Student_Number)
{
    Write-Host "`nThe OU <s139965> already exists in the OU <$OU_Input>`n" -ForegroundColor Red
}

# Check if the OU's 'groups' and 'users' already exist in the above OU, if not create them.

if (!$OU_True_users)
{
    New-ADOrganizationalUnit -Name 'users' -Path "OU=s139965,OU=OS Scripting 23,$Domain"
    Write-Host "`nThe OU <users> was created in the OU <s139965>`n" -ForegroundColor Green
}
elseif ($OU_True_users)
{
    Write-Host "`nThe OU <users> already exists in the OU <s139965>`n" -ForegroundColor Red
}

if (!$OU_True_groups)
{
    New-ADOrganizationalUnit -Name 'groups' -Path "OU=s139965,OU=OS Scripting 23,$Domain"
    Write-Host "`nThe OU <groups> was created in the OU <s139965>`n" -ForegroundColor Green
}
elseif ($OU_True_groups)
{
    Write-Host "`nThe OU <groups> already exists in the OU <s139965>`n" -ForegroundColor Red
}