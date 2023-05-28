Clear-Host

Import-Module AzureAD

$sessOptions = New-PSSessionOption -SkipCACheck -SkipCNCheck
Import-Certificate -Filepath "C:\cert" -CertStoreLocation "Cert:\LocalMachine\Root"
Enter-PSSession -ComputerName PSFV1MS.poliformams.local -UseSSL -SessionOption $sessOptions
Invoke-Command -ComputerName PSFV1MS.poliformams.local -UseSSL -ScriptBlock {Get-Process} -Credential (Get-Credential)
Add-Content $Env:SystemRoot\system32\drivers\etc\hosts PSFV1MS.poliformams.local