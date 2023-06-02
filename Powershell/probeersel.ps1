Clear-Host

Import-Module AzureAD

# Connect to AzureAD.

Connect-AzureAD

# Copy the groups from Azure of which you are member.

$User = 's139965@ap.be'
$User_Id = (Get-AzureADUser -Filter "UserPrincipalName eq '$User'").ObjectId
$Azure_Groups = Get-AzureADUserMembership -ObjectId $User_Id | Get-AzureADGroup
$Azure_Group_Pattern = "22-23 *"

# Import-Module ActiveDirectory on the local Active Directory server.

$AD_Server = Read-Host -Prompt (Write-Host "To which Active Directory Server would you like to connect?" -ForegroundColor Yellow) 

Invoke-Command -ComputerName $AD_Server -Command {
    Import-Module ActiveDirectory
}

# Define variables.

$OU_Input = Read-Host -Prompt (Write-Host "Which OU would you like to create for further use within this script?" -ForegroundColor Yellow)
$Student_Number = 's139965'

$Out_1 = Invoke-Command -ComputerName $AD_Server -Command {
    param($OU_Input, $Student_Number)
    $OU_True_Input = Get-ADOrganizationalUnit -Filter "Name -eq `"$OU_Input`""
    $OU_True_Student_Number = Get-ADOrganizationalUnit -Filter "Name -eq '$Student_Number'"
    $OU_True_Users = Get-ADOrganizationalUnit -Filter "Name -eq 'users'"
    $OU_True_Groups = Get-ADOrganizationalUnit -Filter "Name -eq 'groups'"
    $Domain = (Get-ADDomain).DistinguishedName
    $Domain_Print = (Get-ADDomain).DNSRoot
    return $OU_True_Input, $OU_True_Student_Number, $OU_True_Users, $OU_True_Groups, $Domain, $Domain_Print
} -ArgumentList ($OU_Input, $Student_Number)

$OU_True_Input = $Out_1[0]
$OU_True_Student_Number = $Out_1[1]
$OU_True_Users = $Out_1[2]
$OU_True_Groups = $Out_1[3]
$Domain = $Out_1[4]
$Domain_Print = $Out_1[5]

# Check if a given OU already exists in the current domain, if not create it.

if (!$OU_True_Input) {
    Invoke-Command -ComputerName $AD_Server -Command {
        New-ADOrganizationalUnit -Name $OU_Input -Path "$Domain" -ProtectedFromAccidentalDeletion $false
    }
    Write-Host "The OU <$OU_Input> was created in the domain <$Domain_Print>" -ForegroundColor Green
}
elseif ($OU_True_Input){
    Write-Host "The OU <$OU_Input> already exists in the domain <$Domain_Print>" -ForegroundColor Red
}

# Check if the OU 's139965' already exists in the above OU, if not create it.

if (!$OU_True_Student_number) {
    Invoke-Command -ComputerName $AD_Server -Command {
        New-ADOrganizationalUnit -Name $Student_Number -Path "OU=$OU_Input,$Domain" -ProtectedFromAccidentalDeletion $false
    }
    Write-Host "The OU <$Student_Number> was created in the OU <$OU_Input>" -ForegroundColor Green
}
elseif ($OU_True_Student_Number) {
    Write-Host "The OU <$Student_Number> already exists in the OU <$OU_Input>" -ForegroundColor Red
}

# Check if the OU's 'groups' and 'users' already exist in the above OU, if not create them.

if (!$OU_True_Users) {
    Invoke-Command -ComputerName $AD_Server -Command {
        New-ADOrganizationalUnit -Name 'users' -Path "OU=$Student_Number,OU=$OU_Input,$Domain" -ProtectedFromAccidentalDeletion $false
    }
    Write-Host "The OU <users> was created in the OU <$Student_Number>" -ForegroundColor Green
}
elseif ($OU_True_Users) {
    Write-Host "The OU <users> already exists in the OU <$Student_Number>" -ForegroundColor Red
}

if (!$OU_True_Groups) {
    Invoke-Command -ComputerName $AD_Server -Command {
        New-ADOrganizationalUnit -Name 'groups' -Path "OU=$Student_Number,OU=$OU_Input,$Domain" -ProtectedFromAccidentalDeletion $false
    }
    Write-Host "The OU <groups> was created in the OU <$Student_Number>" -ForegroundColor Green
}
elseif ($OU_True_Groups) {
    Write-Host "The OU <groups> already exists in the OU <$Student_Number>" -ForegroundColor Red
}

# Copy all groups that you are member off from Azure AD to the OU 'groups'.
# Copy all users that are member of those groups from Azure AD to the OU 'users'.
# Copy all users that are member of those groups to their respective groups in the OU 'groups'.

foreach ($Azure_Group in $Azure_Groups) {
    if ($Azure_Group.DisplayName -like $Azure_Group_Pattern) {
        $AD_Group = $Azure_Group.DisplayName.Substring(6)
        $AD_Group = $AD_Group.Substring(0, $AD_Group.Length - 14)
        $Out_2 = Invoke-Command -ComputerName $AD_Server -Command {
            param($AD_Group)
            $AD_True_Group = Get-ADGroup -Filter "Name -eq `"$AD_Group`""
            return $AD_True_Group
        } -ArgumentList ($AD_Group)

        $AD_True_Group = $Out_2[0]

        if (!$AD_True_Group) {
            Invoke-Command -ComputerName $AD_Server -Command {
                New-ADGroup -Name $AD_Group -GroupScope Global -Path "OU=groups,OU=$Student_Number,OU=$OU_Input,$Domain" 
            }
            Write-Host "The group <$AD_Group> was created in the OU <groups>" -ForegroundColor Green
        }
        elseif ($AD_True_Group) {
            Write-Host "The group <$AD_Group> already exists in the OU <groups>" -ForegroundColor Red
        }

        # Copy all users in those groups to Active Directory, and put them in the relevant groups.

        $Out_3 = $Azure_Group_Members = Get-AzureADGroupMember -ObjectId $Azure_Group.ObjectId
        Invoke-Command -ComputerName $AD_Server -Command {
            $AD_Group_Members = Get-ADGroupMember -Identity $AD_Group
            return $AD_Group_Members
            }

            $AD_Group_Members = $Out_3[0]

        foreach ($Azure_Group_Member in $Azure_Group_Members) {
            $Out_4 = Invoke-Command -ComputerName $AD_Server -Command {
                param($Azure_Group_Member, $Azure_Group_Members)
                $AD_User_Exists = Get-ADUser -Filter "UserPrincipalName -eq `"$($Azure_Group_Member.UserPrincipalName)`""
                $AD_User_In_AD_Group = $AD_Group_Members | Where-Object {$_.SamAccountName -eq $Azure_Group_Member.UserPrincipalName}
                return $AD_User_Exists, $AD_User_In_AD_Group
            } -ArgumentList ($Azure_Group_Member, $Azure_Group_Members)

            $AD_User_Exists = $Out_4[0]
            $AD_User_In_AD_Group = $Out_5[1]

            if (!$AD_User_Exists -and $Azure_Group_Member.UserPrincipalName.StartsWith('s') -and $Azure_Group_Member.UserPrincipalName.EndsWith('@ap.be')) {
                Invoke-Command -ComputerName $AD_Server -Command {
                    New-ADUser -Name $Azure_Group_Member.UserPrincipalName -UserPrincipalName $Azure_Group_Member.UserPrincipalName -Path "OU=users,OU=$Student_Number,OU=$OU_Input,$Domain"
                }
                Write-Host "User <$($Azure_Group_Member.UserPrincipalName)> was created in the OU <users>'" -ForegroundColor Green
            }
            elseif ($AD_User_Exists -and $Azure_Group_Member.UserPrincipalName.StartsWith('s') -and $Azure_Group_Member.UserPrincipalName.EndsWith('@ap.be')) {
                Write-Host "User <$($Azure_Group_Member.UserPrincipalName)> already exists in the OU <users>" -ForegroundColor Red
            }

            if (!$AD_User_In_AD_Group -and $Azure_Group_Member.UserPrincipalName.StartsWith('s') -and $Azure_Group_Member.UserPrincipalName.EndsWith('@ap.be')) {
                Invoke-Command -ComputerName $AD_Server -Command {
                    Add-ADGroupMember -Identity $AD_Group -Members $Azure_Group_Member.UserPrincipalName
                } 
                Write-Host "User <$($Azure_Group_Member.UserPrincipalName)> was added to the group <$AD_Group>" -ForegroundColor Green
            } 
            elseif ($AD_User_In_AD_Group -and $Azure_Group_Member.UserPrincipalName.StartsWith('s') -and $Azure_Group_Member.UserPrincipalName.EndsWith('@ap.be')) {
                Write-Host "User <$($Azure_Group_Member.UserPrincipalName)> is already a member of the group <$AD_Group>" -ForegroundColor Red
            }
        }
    }
}