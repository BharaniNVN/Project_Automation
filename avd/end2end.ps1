param ([Parameter(Mandatory)]$existingWVDHostPoolName)

$Environment = Get-AutomationVariable -Name 'Environment'
if ($Environment -eq "DEV" )
{
$location='eastus2'
$azureSubscriptionID="2a446209-14c5-4e44-b98f-446bb4470d07"
$resourceGroupName='phx-wvd-rg-dev'
$vnetRG='phx-parent-rg-dev'
$phxvnetname='phx-base-vnet-dev'
$tempsubnet='phx-wvd-create-subnet-dev'
$subnet='phx-nhiwvd-subnet-dev'
$phxouname='PHX_NHIWVD_DEV'
#$phxouname='phx_wvdsupport'
$phxAibRG='phx-aib-pilot-rg-dev'
$phxCustomImageSourceId="/subscriptions/$azureSubscriptionID/resourceGroups/$phxAibRG/providers/Microsoft.Compute/galleries/PhxImageGallery/images/PhxWin10NhiUsersImage"
.\ConnectAZAccount-nhi-iac-uap-dev-sp.ps1
.\ConnectPostGreSqlDb.ps1 -dbname  'phx-postgres-db-dev' -Server 'phx-postgres-dev.postgres.database.azure.com'
}

if ($Environment -eq "PRD")
{
$location='eastus2'
$azureSubscriptionID="f1f65b4f-f679-4f54-9c3a-0ad664e25120"
$resourceGroupName='phx-wvd-rg-prd'
$vnetRG='phx-parent-rg-prd'
$phxvnetname='phx-base-vnet-prd'
$tempsubnet='phx-wvd-create-subnet-prd'
$subnet='phx-nhiwvd-subnet-prd'
$phxouname='PHX_NHIWVD_PRD'
#$phxouname='phx_wvdsupport'
$phxAibRG='phx-aib-pilot-rg-prd'
$phxCustomImageSourceId="/subscriptions/$azureSubscriptionID/resourceGroups/$phxAibRG/providers/Microsoft.Compute/galleries/PhxImageGallery/images/PhxWin10NhiUsersImage"
.\ConnectAZAccount-nhi-iac-uap-prd-sp.ps1
.\ConnectPostGreSqlDb.ps1 -dbname  'phx-postgres-db-prd' -Server 'phx-postgres-prd.postgres.database.azure.com'
}

#Check VM does not exist already
#####################################Write code in this block later######
#####################################

#Get the VM name to be created
$queryvmnamemax="select max(upper(vm_name_prefix)) as vmnamemax, count(*) as rowcount from nhi_phx_vdi;"
$queryvmnamemax
$queryvmnamemaxresult=Invoke-SqlQuery -Query $queryvmnamemax
$vmnamemax=$queryvmnamemaxresult.vmnamemax
if (($queryvmnamemaxresult.rowcount -eq 0) -And ($Environment -eq "DEV") ) {$vmnamemax='VD-NHI-0'}
if (($queryvmnamemaxresult.rowcount -eq 0) -And ($Environment -eq "PRD") ) {$vmnamemax='VP-NHI-0'}
$vmnamemax
$vmNamePrefix1=$vmnamemax.split("-")[0]
$vmNamePrefix2=$vmnamemax.split("-")[1]
$vmNamePrefix3=[int]$vmnamemax.split("-")[2] + 1
$vmNamePrefix=$vmNamePrefix1+"-"+$vmNamePrefix2+"-"+$vmNamePrefix3

$vmnameversion='V0'
$vmNamePrefixV0=$vmNamePrefix+"-"+$vmnameversion
$vmname=$vmNamePrefixV0+"-0"
$vmnamefull=$vmname+".uapcld.net"
$vmnamefull

#Create the VDI
write-output("PhxCreateNhiUserVDI Started")
date
.\PhxCreateNhiUserVDI.ps1 -existingWVDHostPoolName $existingWVDHostPoolName -VMNamePrefix $vmNamePrefixV0
write-output("PhxCreateNhiUserVDI finished")
date

#Waiting to check if the VM is available
[int]$counter = 10
while ( ($counter -gt 0 ) -AND (Get-AzWvdSessionHost -ResourceGroupName $resourceGroupName -HostPoolName $existingWVDHostPoolName -Name $vmnamefull -ErrorAction silentlycontinue).status -ne 'Available') { write-output("$vmnamefull currently Unavailable so Sleeping $counter");start-sleep -s 30 ; $counter--;
if ($counter -EQ 0) {write-output("waited too long for VM session host Availability so exiting");Exit}}


#Add Agents to the VDI
.\PhxAddAgentsVM.ps1 -vmName $vmname -location $location -ResourceGroupName $ResourceGroupName
write-output("PhxAddAgentsVM finished")
date

#Waiting to check if the VM is available
[int]$counter = 10
while ( ($counter -gt 0 ) -AND (Get-AzWvdSessionHost -ResourceGroupName $resourceGroupName -HostPoolName $existingWVDHostPoolName -Name $vmnamefull -ErrorAction silentlycontinue).status -ne 'Available') { write-output("$vmnamefull currently Unavailable so Sleeping $counter");start-sleep -s 30 ; $counter--;
if ($counter -EQ 0) {write-output("waited too long for VM session host Availability so exiting");Exit}}


#Update right Subnet
.\PhxChangeSubnetVM.ps1 -vmName $vmname -ResourceGroupName $ResourceGroupName -TargetSubnetName $subnet

#Waiting to check if the VM is available
[int]$counter = 10
while ( ($counter -gt 0 ) -AND (Get-AzWvdSessionHost -ResourceGroupName $resourceGroupName -HostPoolName $existingWVDHostPoolName -Name $vmnamefull -ErrorAction silentlycontinue).status -ne 'Available') { write-output("$vmnamefull currently Unavailable so Sleeping $counter");start-sleep -s 30 ; $counter--;
if ($counter -EQ 0) {write-output("waited too long for VM session host Availability so exiting");Exit}}

#Make entry into the post gresql table nhi_phx_vdi for newly created VDI
$queryusername="INSERT INTO nhi_phx_vdi(hostpoolname,vm_name_prefix,vm_name_version,vm_name) values('"+$existingWVDHostPoolName+"','"+$vmNamePrefix+"','"+$vmnameversion+"','"+$vmname+"');"
$queryusername
$queryusernameresult=Invoke-SqlQuery -Query $queryusername
$queryusernameresult
