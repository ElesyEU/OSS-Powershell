Clear-Host

Import-Module AzureAD

# Check if a given OU already exists, if not create it.

$OU_Input = Read-Host -Prompt (Write-Host "Which OU would you like to create for further use within this script?`n" -ForegroundColor Yellow)
$OU_True_OS_Scripting_23 = Get-ADOrganizationalUnit -Filter "Name -eq 'OS Scripting 23'"
$OU_True_Student_Number = Get-ADOrganizationalUnit -Filter "Name -eq 's139965'"
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

# Inside the above OU create a new OU with your student number if it does not exist yet.

if (!$OU_True_Student_number)
{
    New-ADOrganizationalUnit -Name 's139965' -Path "OU=$OU_Input,$Domain"
    Write-Host "`nThe OU <s139965> was created in the OU <$OU_Input>`n" -ForegroundColor Green
}
elseif ($OU_True_Student_Number)
{
    Write-Host "`nThe OU <s139965> already exists in the OU <$OU_Input>`n" -ForegroundColor Red
}