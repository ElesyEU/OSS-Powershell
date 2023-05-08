Clear-Host

Import-Module Microsoft.PowerShell.Utility

if (Test-Path ".\recovered")
{Remove-Item .\recovered -Recurse -Force}
Expand-Archive recovered.zip

$login = "www"
$dns = Resolve-DnsName _access.dieter.afterthought.be -Type TXT
$password = $dns.Strings[0]
$cred = New-Object System.Management.Automation.PSCredential ($login, ($password | ConvertTo-SecureString -AsPlainText -Force))


try { Invoke-WebRequest -Uri https://dieter.afterthought.be/metadata/emoji.csv -Credential $cred -OutFile "C:\Users\vaags\Downloads\csvfile.csv" }
catch { "An error occured while trying to download the .csv file." }