Param([parameter(Mandatory=$true)] [string]$server, [parameter(Mandatory=$true)] [string]$dbname)
Import-Module SimplySql -Force
# Get-Module SimplySql | Select-Object ModuleType, Version, Name
# (Get-Module SimplySql).ExportedCommands.Keys | Where-Object { $_ -like "open*"}


$cred = Get-AutomationPSCredential -Name $dbname
$User = $cred.username
$PWord = $cred.GetNetworkCredential().Password
$securepass = ConvertTo-SecureString -String $PWord -AsPlainText -Force
$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $securepass

#$server='phx-postgres-dev.postgres.database.azure.com'
#$db='phx-postgres-db-dev'
Open-PostGreconnection -Server $server -Database $dbname -Credential $Credential -Port 5432
