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

Write-Host $csvobject | Where-Object { $_.Name, $_.MD5}
Write-Host $recovered

foreach ($item in $recovered)
{
    $filehash = Get-FileHash $item -Algorithm MD5 | Select-Object
    Write-Host $filehash
}