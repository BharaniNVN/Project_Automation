param ([Parameter(Mandatory)] $ARM_SUBSCRIPTION_ID,[Parameter(Mandatory)] $ARM_CLIENT_ID,[Parameter(Mandatory)] $ARM_CLIENT_SECRET,[Parameter(Mandatory)] $ARM_TENANT_ID)
try
{
$ErrorActionPreference = "Stop"
write-output("subscription id is $ARM_SUBSCRIPTION_ID")
$PWord = ConvertTo-SecureString -String $ARM_CLIENT_SECRET -AsPlainText -Force
$Creds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $ARM_CLIENT_ID, $PWord
'Az.Accounts','Az.Resources','Az.ImageBuilder', 'Az.ManagedServiceIdentity', 'Az.Compute', 'Az.Storage', 'Az.Automation' | ForEach-Object {Install-Module -Name $_ -AllowPrerelease -Force}
Connect-AzAccount -Credential $Creds -Tenant $ARM_TENANT_ID -ServicePrincipal
write-output("Build Step")


if ( $ARM_SUBSCRIPTION_ID -eq "2a446209-14c5-4e44-b98f-446bb4470d07" )
{
$file = Import-Csv -Path ./RunBooksName_dev.txt -delimiter '|'
$ResourceGroupName = 'phx-data-management-rg-dev'
$location = (Get-AzResourceGroup -Name $ResourceGroupName).Location
$AutomationAccountName='phx-default-aa-dev'


}

if ( $ARM_SUBSCRIPTION_ID -eq "f1f65b4f-f679-4f54-9c3a-0ad664e25120" )
{
$file = Import-Csv -Path ./RunBooksName_prd.txt -delimiter '|'
$ResourceGroupName = 'phx-data-management-rg-prd'
$location = (Get-AzResourceGroup -Name $ResourceGroupName).Location
$AutomationAccountName='phx-default-aa-prd'
}
$file
foreach ( $i in $file )
 { 
    $RunbooksFilePath = "./RunBooks/"
    $RunBookNameFull=$i.RunBookName
    $RunBookName=$i.RunBookName.replace(".PS1","").replace(".ps1","").replace(".py","").replace(".PY","")
    $Type=$i.Type
    $ToDeploy=$i.ToDeploy

    if (-not(Test-Path -Path $RunbooksFilePath/$RunBookNameFull -PathType Leaf)) 
    {
     write-output("Run Book file $RunbooksFilePath/$RunBookName is missing, So Exiting`r`n")
     exit
    }

write-output("Now starting build for Run Book file $RunbooksFilePath/$RunBookName `r`n")
if ($i.ToDeploy -eq "Y")
{
#Deploy the run Book
$params = @{
    AutomationAccountName = $AutomationAccountName
    ResourceGroupName     = $ResourceGroupName
    Name                  = $RunBookName
    Type                  = $Type
    Path                  = "$RunbooksFilePath/$RunBookNameFull"
}
Import-AzAutomationRunbook -Force @params

#Publish the run Book
$publishParams = @{
    AutomationAccountName = $AutomationAccountName
    ResourceGroupName     = $ResourceGroupName
    Name                  = $RunBookName
}
Publish-AzAutomationRunbook @publishParams
}
}
}
catch
{
$ErrorMessage = $_.Exception.Message
$FailedItem = $_.Exception.ItemName
write-output ("$FailedItem with message $ErrorMessage")
}
