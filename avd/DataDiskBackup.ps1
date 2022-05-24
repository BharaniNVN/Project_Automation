Param(

     [parameter(Mandatory=$true)]
     [string]$dataDiskName
)

$Environment = Get-AutomationVariable -Name 'Environment'
if ( $Environment -eq "DEV")
{
.\ConnectAZAccount-nhi-iac-uap-dev-sp.ps1
$azureSubscriptionID="2a446209-14c5-4e44-b98f-446bb4470d07"
$resourceGroupName='phx-wvd-rg-dev'
$VaultName ='phx-Backupvault-dev'
$SnapshotRg='phx-snapshotrg-dev'
}

if ( $Environment -eq "PRD")
{
.\ConnectAZAccount-nhi-iac-uap-prd-sp.ps1    
$azureSubscriptionID="f1f65b4f-f679-4f54-9c3a-0ad664e25120"
$resourceGroupName='phx-wvd-rg-prd'
$VaultName ='phx-Backupvault-prd'
$SnapshotRg='phx-snapshotrg-prd'
}

##### Role Assignment ####
$MID=(Get-AzDataProtectionBackupVault -SubscriptionId $azureSubscriptionID -ResourceGroupName $resourceGroupName -VaultName $VaultName).identity.principalid
$DiskId=(Get-AzDisk -ResourceGroupName $resourceGroupName -DiskName $dataDiskName).id


#$AzureDiskId= "/subscriptions/2a446209-14c5-4e44-b98f-446bb4470d07/resourcegroups/phx-wvd-pilot-rg-dev/providers/Microsoft.Compute/disks/Test-Bharani"
New-AzRoleAssignment -ObjectId $MID -RoleDefinitionName "Disk Backup Reader" -Scope $DiskId

 

#### Backup Vault & policy #####
$Backupvault = Get-AzDataProtectionBackupVault -SubscriptionId $azureSubscriptionID -ResourceGroupName $resourceGroupName
$policy = Get-AzDataProtectionBackupPolicy -SubscriptionId $azureSubscriptionID -ResourceGroupName $resourceGroupName  -VaultName $VaultName

 

##### preparing Disk for Backup #####
$instance = Initialize-AzDataProtectionBackupInstance -DatasourceType AzureDisk -DatasourceLocation eastus2 -DatasourceId $DiskId -PolicyId $policy[0].Id
$instance.Property.PolicyInfo.PolicyParameter.DataStoreParametersList[0].ResourceGroupId = "/subscriptions/$azureSubscriptionID/resourceGroups/$SnapshotRg"
New-AzDataProtectionBackupInstance -ResourceGroupName $resourceGroupName -VaultName $Backupvault.Name -BackupInstance $instance 

### It Removes all Backup Instances
#$AllInstances = Get-AzDataProtectionBackupInstance -ResourceGroupName $resourceGroupName" -VaultName $VaultName
#$AllInstances
#Remove-AzDataProtectionBackupInstance -SubscriptionId "2a446209-14c5-4e44-b98f-446bb4470d07" -ResourceGroupName "phx-wvd-rg-dev" -VaultName "phx-Backupvault-dev" -Name $AllInstances[0].name
