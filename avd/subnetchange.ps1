param ([Parameter(Mandatory)]$VMNAME,[Parameter(Mandatory)]$ResourceGroupName,[Parameter(Mandatory)]$TargetSubnetName)

$Environment = Get-AutomationVariable -Name 'Environment'
if ( $Environment -eq "DEV")
{
.\ConnectAZAccount-nhi-iac-uap-dev-sp.ps1
}

if ( $Environment -eq "PRD")
{
.\ConnectAZAccount-nhi-iac-uap-prd-sp.ps1
}

$VMNAME=$VMNAME
$ResourceGroupName=$ResourceGroupName
$TargetSubnetName=$TargetSubnetName
$VMDETAILS = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $VMNAME
$VMNIC=$VMDETAILS.NetworkProfile.NetworkInterfaces.Id
$NICDETAILS = Get-AzNetworkInterface -ResourceGroupName $ResourceGroupName -Name $VMNIC.Split('/')[-1] 
$VNETRG=$NICDETAILS.IpConfigurations.Subnet.Id.Split('/')[-7]
$VNETNAME=$NICDETAILS.IpConfigurations.Subnet.Id.Split('/')[-3]
$VNET = Get-AzVirtualNetwork -Name $VNETNAME -ResourceGroupName $VNETRG
$TargetSubnet = Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $VNET -Name $TargetSubnetName
$NICDETAILS.IpConfigurations[0].Subnet.Id = $TargetSubnet.Id
$NICDETAILS
Set-AzNetworkInterface -NetworkInterface $NICDETAILS
