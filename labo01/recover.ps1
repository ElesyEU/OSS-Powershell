Clear-Host

Import-Module Microsoft.PowerShell.Utility

if (Test-Path ".\recovered")
{Remove-Item .\recovered -Recurse -Force}
Expand-Archive recovered.zip

if (Test-Path ".\csvfile.csv")
{Remove-Item .\csvfile.csv -Recurse -Force}

$login = "www"
$dns = Resolve-DnsName _access.dieter.afterthought.be -Type TXT
$password = $dns.Strings[0]
$cred = New-Object System.Management.Automation.PSCredential ($login, ($password | ConvertTo-SecureString -AsPlainText -Force))

try { Invoke-WebRequest -Uri https://dieter.afterthought.be/metadata/emoji.csv -Credential $cred -OutFile ".\csvfile.csv" }
catch { "An error occured while trying to download the .csv file." }

Remove-Item .\recovered\README.txt

$csv = Get-Content csvfile.csv
$csvobject = $csv | ConvertFrom-Csv
$recovered = Get-ChildItem .\recovered

foreach ($item in $recovered)
{
    $filehash = $item | Get-FileHash -Algorithm MD5
    $item | Rename-Item -NewName ($csvobject | Where-Object { $_.MD5 -eq $filehash.Hash }).Name
}

Compress-Archive .\recovered -DestinationPath C:\Users\vaags\downloads\fixed