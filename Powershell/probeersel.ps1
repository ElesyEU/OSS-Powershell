Clear-Host

<#
Specify a user (for example 's139965@ap.be'), all groups that this user is member off will be copied from AzureAD for further use in the script.
Specify an OU you wish to create (for example 'OS Scripting 23').
Create this OU in Active Directory.
Create an OU in it named 's139965'.
Create OU's in it named 'users' and 'groups'.
In 'groups' import the groups that were copied from AzureAD.
In 'users' import the users that are member of the copied groups.
Add the users to their respective groups.
#>

Import-Module AzureAD

# Connect to AzureAD.

Connect-AzureAD

# Copy the groups from Azure of which you are member and show a progress bar.

$User = Read-Host -Prompt (Write-Host "Specify a User -for example 's139965@ap.be'-, all groups that this user is member of will be copied from AzureAD for further use in the script." -ForegroundColor Yellow) 
$User_Id = (Get-AzureADUser -Filter "UserPrincipalName eq '$User'").ObjectId
$Azure_Group_Pattern = "22-23 *"

$Write_Progress = @{
    Activity = "Copying Groups from Azure AD"
    PercentComplete = 0
}

Write-Progress @Write_Progress

$Azure_Groups = Get-AzureADUserMembership -ObjectId $User_Id | Get-AzureADGroup
$Azure_Group_Count = $Azure_Groups.Count
$Copied_Azure_Groups = 0

foreach ($Azure_Group in $Azure_Groups) {
    $Copied_Azure_Groups++
    $Write_Progress.PercentComplete = ($Copied_Azure_Groups / $Azure_Group_Count) * 100

    Write-Progress @Write_Progress
}

$Write_Progress.Activity = "Copying Groups from Azure AD"
$Write_Progress.PercentComplete = 100

Write-Progress @Write_Progress -Completed


# Import-Module ActiveDirectory on the local Active Directory server.

$AD_Server = 'localhost'

Invoke-Command -ComputerName $AD_Server -Command {
    Import-Module ActiveDirectory
}

# Define variables.

$OU_Input = Read-Host -Prompt (Write-Host "Which OU would you like to create for further use within this script?" -ForegroundColor Yellow)
$Student_Number = 's139965'

# Retrieve variables individually using separate Invoke-Command blocks.

$OU_True_Input = Invoke-Command -ComputerName $AD_Server -Command {
    param($OU_Input)
    Get-ADOrganizationalUnit -Filter "Name -eq `"$OU_Input`"" -ErrorAction SilentlyContinue
} -ArgumentList $OU_Input

$OU_True_Student_Number = Invoke-Command -ComputerName $AD_Server -Command {
    param($Student_Number)
    Get-ADOrganizationalUnit -Filter "Name -eq '$Student_Number'" -ErrorAction SilentlyContinue
} -ArgumentList $Student_Number

$OU_True_Users = Invoke-Command -ComputerName $AD_Server -Command {
    Get-ADOrganizationalUnit -Filter "Name -eq 'users'" -ErrorAction SilentlyContinue
}

$OU_True_Groups = Invoke-Command -ComputerName $AD_Server -Command {
    Get-ADOrganizationalUnit -Filter "Name -eq 'groups'" -ErrorAction SilentlyContinue
}

$Domain = Invoke-Command -ComputerName $AD_Server -Command {
    (Get-ADDomain).DistinguishedName
}

$Domain_Print = Invoke-Command -ComputerName $AD_Server -Command {
    (Get-ADDomain).DNSRoot
}

# Check if a given OU already exists in the current domain, if not create it.

if (!$OU_True_Input) {
    Invoke-Command -ComputerName $AD_Server -Command {
        param($OU_Input, $Domain)
        New-ADOrganizationalUnit -Name "$OU_Input" -Path "$Domain" -ProtectedFromAccidentalDeletion $false
    } -ArgumentList $OU_Input, $Domain
    Write-Host "The OU <$OU_Input> was created in the domain <$Domain_Print>" -ForegroundColor Green
}
elseif ($OU_True_Input){
    Write-Host "The OU <$OU_Input> already exists in the domain <$Domain_Print>" -ForegroundColor Red
}

# Check if the OU 's139965' already exists in the above OU, if not create it.

if (!$OU_True_Student_number) {
    Invoke-Command -ComputerName $AD_Server -Command {
        param($Student_Number, $OU_Input, $Domain)
        New-ADOrganizationalUnit -Name $Student_Number -Path "OU=$OU_Input,$Domain" -ProtectedFromAccidentalDeletion $false
    } -ArgumentList $Student_Number, $OU_Input, $Domain
    Write-Host "The OU <$Student_Number> was created in the OU <$OU_Input>" -ForegroundColor Green
}
elseif ($OU_True_Student_Number) {
    Write-Host "The OU <$Student_Number> already exists in the OU <$OU_Input>" -ForegroundColor Red
}

# Check if the OU's 'groups' and 'users' already exist in the above OU, if not create them.

if (!$OU_True_Users) {
    Invoke-Command -ComputerName $AD_Server -Command {
        param($Student_Number, $OU_Input, $Domain)
        New-ADOrganizationalUnit -Name 'users' -Path "OU=$Student_Number,OU=$OU_Input,$Domain" -ProtectedFromAccidentalDeletion $false
    } -ArgumentList $Student_Number, $OU_Input, $Domain
    Write-Host "The OU <users> was created in the OU <$Student_Number>" -ForegroundColor Green
}
elseif ($OU_True_Users) {
    Write-Host "The OU <users> already exists in the OU <$Student_Number>" -ForegroundColor Red
}

if (!$OU_True_Groups) {
    Invoke-Command -ComputerName $AD_Server -Command {
        param($Student_Number, $OU_Input, $Domain)
        New-ADOrganizationalUnit -Name 'groups' -Path "OU=$Student_Number,OU=$OU_Input,$Domain" -ProtectedFromAccidentalDeletion $false
    } -ArgumentList $Student_Number, $OU_Input, $Domain
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
        $AD_True_Group = Invoke-Command -ComputerName $AD_Server -Command {
            param($AD_Group)
            $AD_True_Group = Get-ADGroup -Filter "Name -eq `"$AD_Group`""
            return [bool]$AD_True_Group
        } -ArgumentList $AD_Group

        if (!$AD_True_Group) {
            Invoke-Command -ComputerName $AD_Server -Command {
                param($AD_Group, $Student_Number, $OU_Input, $Domain)
                Try {
                    New-ADGroup -Name $AD_Group -GroupScope Global -Path "OU=groups,OU=$Student_Number,OU=$OU_Input,$Domain"
                }
                Catch {
                    $null
                }
            } -ArgumentList $AD_Group, $Student_Number, $OU_Input, $Domain, $AD_True_Group
            Write-Host "The group <$AD_Group> was created in the OU <groups>" -ForegroundColor Green
        }
        elseif ($AD_True_Group) {
            Write-Host "The group <$AD_Group> already exists in the OU <groups>" -ForegroundColor Red
        }

        # Copy all users in those groups to Active Directory, and put them in the relevant groups.

        $Azure_Group_Members = Get-AzureADGroupMember -ObjectId $Azure_Group.ObjectId
        $AD_Group_Members = Invoke-Command -ComputerName $AD_Server -Command {
            param($AD_Group)
            $AD_Group_Members = Get-ADGroupMember -Identity $AD_Group
        } -ArgumentList $AD_Group

        foreach ($Azure_Group_Member in $Azure_Group_Members) {
            $AD_User_Exists = Invoke-Command -ComputerName $AD_Server -Command {
                param($Azure_Group_Member)
                $AD_User_Exists = Get-ADUser -Filter "UserPrincipalName -eq `"$($Azure_Group_Member.UserPrincipalName)`""
                return [bool]$AD_User_Exists        
            } -ArgumentList $Azure_Group_Member
            
            $AD_User_In_AD_Group = Invoke-Command -ComputerName $AD_Server -Command {
                param($AD_Group_Members, $Azure_Group_Member)
                $AD_User_In_AD_Group = $AD_Group_Members | Where-Object {$_.SamAccountName -eq $Azure_Group_Member.UserPrincipalN}
                return [bool]$AD_User_In_AD_Group
            } -ArgumentList $AD_Group_Members, $Azure_Group_Member


            if (!$AD_User_Exists -and $Azure_Group_Member.UserPrincipalName.StartsWith('s') -and $Azure_Group_Member.UserPrincipalName.EndsWith('@ap.be')) {
                Invoke-Command -ComputerName $AD_Server -Command {
                    param($Azure_Group_Member, $Student_Number, $OU_Input, $Domain)
                    Try {
                        New-ADUser -Name $Azure_Group_Member.UserPrincipalName -UserPrincipalName $Azure_Group_Member.UserPrincipalName -Path "OU=users,OU=$Student_Number,OU=$OU_Input,$Domain"
                    }
                    Catch {
                        $null
                    }
                } -ArgumentList $Azure_Group_Member, $Student_Number, $OU_Input, $Domain
                Write-Host "User <$($Azure_Group_Member.UserPrincipalName)> was created in the OU <users>'" -ForegroundColor Green
            }
            elseif ($AD_User_Exists -and $Azure_Group_Member.UserPrincipalName.StartsWith('s') -and $Azure_Group_Member.UserPrincipalName.EndsWith('@ap.be')) {
                Write-Host "User <$($Azure_Group_Member.UserPrincipalName)> already exists in the OU <users>" -ForegroundColor Red
            }

            if (!$AD_User_In_AD_Group -and $Azure_Group_Member.UserPrincipalName.StartsWith('s') -and $Azure_Group_Member.UserPrincipalName.EndsWith('@ap.be')) {
                Invoke-Command -ComputerName $AD_Server -Command {
                    param($AD_Group, $Azure_Group_Member)
                    Try {
                        Add-ADGroupMember -Identity $AD_Group -Members $Azure_Group_Member.UserPrincipalName
                    }
                    Catch {
                        $null
                    }
                } -ArgumentList $AD_Group, $Azure_Group_Member
                Write-Host "User <$($Azure_Group_Member.UserPrincipalName)> was added to the group <$AD_Group>" -ForegroundColor Green
            } 
            elseif ($AD_User_In_AD_Group -and $Azure_Group_Member.UserPrincipalName.StartsWith('s') -and $Azure_Group_Member.UserPrincipalName.EndsWith('@ap.be')) {
                Write-Host "User <$($Azure_Group_Member.UserPrincipalName)> is already a member of the group <$AD_Group>" -ForegroundColor Red
            }
        }
    }
}