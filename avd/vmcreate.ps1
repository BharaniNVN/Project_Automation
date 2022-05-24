Param(
     [parameter(Mandatory=$false)]
     [string]$existingWVDHostPoolName='phx-host-pool-nhi',
     [parameter(Mandatory=$true)]
     [string]$vmNamePrefix='VM-NHI-1-V0'
)
Add-Type -AssemblyName System.Web
$Credwvdadminnew=Get-AutomationPSCredential -Name 'nhiwvdadminnew'
$vmAdministratorAccountUsername = $Credwvdadminnew.username
$vmAdministratorAccountPassword = $Credwvdadminnew.GetNetworkCredential().Password
$CredadministratorAccountUsername=Get-AutomationPSCredential -Name 'nhiadministratorAccountUsername'
$administratorAccountUsername = $CredadministratorAccountUsername.username
$administratorAccountPassword = $CredadministratorAccountUsername.GetNetworkCredential().Password

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


#Set parameters
# $azureSubscriptionID="2a446209-14c5-4e44-b98f-446bb4470d07"
# $resourceGroupName="phx-wvd-rg-dev"
# $existingWVDHostPoolName="phx-host-pool-nhi"
# $vmNamePrefix="VM-NHI-1"
$deploymentId = "50dd818c-656f-4ca0-adb0-"+$vmNamePrefix

$Registered = Get-AzWvdRegistrationInfo -SubscriptionId "$azureSubscriptionID" -ResourceGroupName "$resourceGroupName" -HostPoolName $existingWVDHostPoolName
if (-not(-Not $Registered.Token)){$registrationTokenValidFor = (NEW-TIMESPAN -Start (get-date) -End $Registered.ExpirationTime | select Days,Hours,Minutes,Seconds)}
write-output( "Token is valid for:$registrationTokenValidFor")
if ((-Not $Registered.Token) -or ($Registered.ExpirationTime -le (get-date)))
{
    $ExpirationTime=(Get-Date).AddHours(10)
    $Registered = New-AzWvdRegistrationInfo -SubscriptionId $azureSubscriptionID -ResourceGroupName $resourceGroupName -HostPoolName $existingWVDHostPoolName -ExpirationTime $ExpirationTime -ErrorAction SilentlyContinue
}
$RdsRegistrationInfotoken = $Registered.Token

##"domain": {
#    "value": "uapcld.net"
#},
#"ouPath": {
#    "value": "OU=PHXWVD,DC=uapcld,DC=net"
#},

$parameters='{
    "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentParameters.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
        "artifactsLocation": {
            "value": "https://wvdportalstorageblob.blob.core.windows.net/galleryartifacts/Configuration_3-10-2021.zip"
        },
        "nestedTemplatesLocation": {
            "value": "https://catalogartifact.azureedge.net/publicartifacts/Microsoft.Hostpool-ARM-1.2.2/"
        },
        "hostpoolName": {
            "value": "<hostpoolName>"
        },
        "hostpoolToken": {
            "value": "<hostpoolToken>"
        },
        "vmAdministratorAccountUsername": {
            "value": "<vmAdministratorAccountUsername>"
        },
        "vmAdministratorAccountPassword": {
            "value": "<vmAdministratorAccountPassword>"
        },
        "administratorAccountUsername": {
            "value": "<administratorAccountUsername>"
        },
        "administratorAccountPassword": {
            "value": "<administratorAccountPassword>"
        },
        "hostpoolResourceGroup": {
            "value": "<hostpoolResourceGroup>"
        },
        "hostpoolProperties": {
            "value": {}
        },
        "hostpoolLocation": {
            "value": "eastus2"
        },
        "availabilityOption": {
            "value": "None"
        },
        "availabilitySetName": {
            "value": ""
        },
        "createAvailabilitySet": {
            "value": false
        },
        "availabilitySetUpdateDomainCount": {
            "value": 5
        },
        "availabilitySetFaultDomainCount": {
            "value": 2
        },
        "availabilityZone": {
            "value": 1
        },
        "vmInitialNumber": {
            "value": 0
        },
        "vmResourceGroup": {
            "value": "<vmResourceGroup>"
        },
        "vmLocation": {
            "value": "eastus2"
        },
        "vmSize": {
            "value": "Standard_D8ds_v4"
        },
        "vmNumberOfInstances": {
            "value": 1
        },
        "vmNamePrefix": {
            "value": "<vmNamePrefix>"
        },
        "vmImageType": {
            "value": "CustomImage"
        },
        "vmDiskType": {
            "value": "StandardSSD_LRS"
        },
        "vmUseManagedDisks": {
            "value": true
        },
        "existingVnetName": {
            "value": "<phxvnetname>"
        },
        "existingSubnetName": {
            "value": "<subnet>"
        },
        "virtualNetworkResourceGroupName": {
            "value": "<vnetRG>"
        },
        "createNetworkSecurityGroup": {
            "value": false
        },
        "domain": {
            "value": "uapcld.net"
        },
        "ouPath": {
            "value": "OU=<phxouname>,DC=uapcld,DC=net"
        },
        "aadJoin": {
            "value": false
        },
        "intune": {
            "value": false
        },
        "availabilitySetTags": {
            "value": {}
        },
        "networkInterfaceTags": {
            "value": {}
        },
        "networkSecurityGroupTags": {
            "value": {}
        },
        "virtualMachineTags": {
            "value": {}
        },
        "imageTags": {
            "value": {}
        },
        "deploymentId": {
            "value": "<deploymentId>"
        },
        "apiVersion": {
            "value": "2019-12-10-preview"
        },
        "vmCustomImageSourceId": {
            "value": "<phxCustomImageSourceId>"
        }
    }
}'

$parameters=$parameters.replace("<hostpoolName>","$existingWVDHostPoolName")
$parameters=$parameters.replace("<hostpoolToken>","$RdsRegistrationInfotoken")
$parameters=$parameters.replace("<vmNamePrefix>","$vmNamePrefix")
$parameters=$parameters.replace("<hostpoolResourceGroup>","$resourceGroupName")
$parameters=$parameters.replace("<deploymentId>","$deploymentId")
$parameters=$parameters.replace("<vmResourceGroup>","$resourceGroupName")
$parameters=$parameters.replace("<phxCustomImageSourceId>","$phxCustomImageSourceId")
$parameters=$parameters.replace("<vnetRG>","$vnetRG")
$parameters=$parameters.replace("<subnet>","$tempsubnet")
$parameters=$parameters.replace("<phxvnetname>","$phxvnetname")
$parameters=$parameters.replace("<phxouname>","$phxouname")
$parameters=$parameters.replace("<vmAdministratorAccountUsername>","$vmAdministratorAccountUsername")
$parameters=$parameters.replace("<vmAdministratorAccountPassword>","$vmAdministratorAccountPassword")
$parameters=$parameters.replace("<administratorAccountUsername>","$administratorAccountUsername")
$parameters=$parameters.replace("<administratorAccountPassword>","$administratorAccountPassword")
$parameters > ./paramfile.json


$templatefile="{
    `"`$schema`": `"https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#`",
    `"contentVersion`": `"1.0.0.0`",
    `"parameters`": {
        `"nestedTemplatesLocation`": {
            `"type`": `"string`",
            `"metadata`": {
                `"description`": `"The base URI where artifacts required by this template are located.`"
            },
            `"defaultValue`": `"https://catalogartifact.azureedge.net/publicartifacts/Microsoft.Hostpool-ARM-1.2.2/`"
        },
        `"artifactsLocation`": {
            `"type`": `"string`",
            `"metadata`": {
                `"description`": `"The base URI where artifacts required by this template are located.`"
            },
            `"defaultValue`": `"https://wvdportalstorageblob.blob.core.windows.net/galleryartifacts/Configuration_3-10-2021.zip`"
        },
        `"hostpoolName`": {
            `"type`": `"string`",
            `"metadata`": {
                `"description`": `"The name of the Hostpool to be created.`"
            }
        },
        `"hostpoolToken`": {
            `"type`": `"securestring`",
            `"metadata`": {
                `"description`": `"The token of the host pool where the session hosts will be added.`"
            }
        },
        `"hostpoolResourceGroup`": {
            `"type`": `"string`",
            `"metadata`": {
                `"description`": `"The resource group of the host pool to be updated. Used when the host pool was created empty.`"
            },
            `"defaultValue`": `"`"
        },
        `"hostpoolLocation`": {
            `"type`": `"string`",
            `"metadata`": {
                `"description`": `"The location of the host pool to be updated. Used when the host pool was created empty.`"
            },
            `"defaultValue`": `"`"
        },
        `"hostpoolProperties`": {
            `"type`": `"object`",
            `"metadata`": {
                `"description`": `"The properties of the Hostpool to be updated. Used when the host pool was created empty.`"
            },
            `"defaultValue`": {}
        },
        `"vmTemplate`": {
            `"type`": `"string`",
            `"metadata`": {
                `"description`": `"The host pool VM template. Used when the host pool was created empty.`"
            },
            `"defaultValue`": `"`"
        },
        `"administratorAccountUsername`": {
            `"type`": `"string`",
            `"metadata`": {
                `"description`": `"A username in the domain that has privileges to join the session hosts to the domain. For example, 'vmjoiner@contoso.com'.`"
            },
            `"defaultValue`": `"`"
        },
        `"administratorAccountPassword`": {
            `"type`": `"securestring`",
            `"metadata`": {
                `"description`": `"The password that corresponds to the existing domain username.`"
            },
            `"defaultValue`": `"`"
        },
        `"vmAdministratorAccountUsername`": {
            `"type`": `"string`",
            `"metadata`": {
                `"description`": `"A username to be used as the virtual machine administrator account. The vmAdministratorAccountUsername and  vmAdministratorAccountPassword parameters must both be provided. Otherwise, domain administrator credentials provided by administratorAccountUsername and administratorAccountPassword will be used.`"
            },
            `"defaultValue`": `"`"
        },
        `"vmAdministratorAccountPassword`": {
            `"type`": `"securestring`",
            `"metadata`": {
                `"description`": `"The password associated with the virtual machine administrator account. The vmAdministratorAccountUsername and  vmAdministratorAccountPassword parameters must both be provided. Otherwise, domain administrator credentials provided by administratorAccountUsername and administratorAccountPassword will be used.`"
            },
            `"defaultValue`": `"`"
        },
        `"availabilityOption`": {
            `"type`": `"string`",
            `"metadata`": {
                `"description`": `"Select the availability options for the VMs.`"
            },
            `"defaultValue`": `"None`",
            `"allowedValues`": [
                `"None`",
                `"AvailabilitySet`",
                `"AvailabilityZone`"
            ]
        },
        `"availabilitySetName`": {
            `"type`": `"string`",
            `"metadata`": {
                `"description`": `"The name of avaiability set to be used when create the VMs.`"
            },
            `"defaultValue`": `"`"
        },
        `"createAvailabilitySet`": {
            `"type`": `"bool`",
            `"metadata`": {
                `"description`": `"Whether to create a new availability set for the VMs.`"
            },
            `"defaultValue`": false
        },
        `"availabilitySetUpdateDomainCount`": {
            `"type`": `"int`",
            `"metadata`": {
                `"description`": `"The platform update domain count of avaiability set to be created.`"
            },
            `"defaultValue`": 5,
            `"allowedValues`": [
                1,
                2,
                3,
                4,
                5,
                6,
                7,
                8,
                9,
                10,
                11,
                12,
                13,
                14,
                15,
                16,
                17,
                18,
                19,
                20
            ]
        },
        `"availabilitySetFaultDomainCount`": {
            `"type`": `"int`",
            `"metadata`": {
                `"description`": `"The platform fault domain count of avaiability set to be created.`"
            },
            `"defaultValue`": 2,
            `"allowedValues`": [
                1,
                2,
                3
            ]
        },
        `"availabilityZone`": {
            `"type`": `"int`",
            `"metadata`": {
                `"description`": `"The number of availability zone to be used when create the VMs.`"
            },
            `"defaultValue`": 1,
            `"allowedValues`": [
                1,
                2,
                3
            ]
        },
        `"vmResourceGroup`": {
            `"type`": `"string`",
            `"metadata`": {
                `"description`": `"The resource group of the session host VMs.`"
            }
        },
        `"vmLocation`": {
            `"type`": `"string`",
            `"metadata`": {
                `"description`": `"The location of the session host VMs.`"
            }
        },
        `"vmSize`": {
            `"type`": `"string`",
            `"metadata`": {
                `"description`": `"The size of the session host VMs.`"
            }
        },
        `"vmInitialNumber`": {
            `"type`": `"int`",
            `"metadata`": {
                `"description`": `"VM name prefix initial number.`"
            }
        },
        `"vmNumberOfInstances`": {
            `"type`": `"int`",
            `"metadata`": {
                `"description`": `"Number of session hosts that will be created and added to the hostpool.`"
            }
        },
        `"vmNamePrefix`": {
            `"type`": `"string`",
            `"metadata`": {
                `"description`": `"This prefix will be used in combination with the VM number to create the VM name. If using 'rdsh' as the prefix, VMs would be named 'rdsh-0', 'rdsh-1', etc. You should use a unique prefix to reduce name collisions in Active Directory.`"
            }
        },
        `"vmImageType`": {
            `"type`": `"string`",
            `"metadata`": {
                `"description`": `"Select the image source for the session host vms. VMs from a Gallery image will be created with Managed Disks.`"
            },
            `"defaultValue`": `"Gallery`",
            `"allowedValues`": [
                `"CustomVHD`",
                `"CustomImage`",
                `"Gallery`",
                `"Disk`"
            ]
        },
        `"vmGalleryImageOffer`": {
            `"type`": `"string`",
            `"metadata`": {
                `"description`": `"(Required when vmImageType = Gallery) Gallery image Offer.`"
            },
            `"defaultValue`": `"`"
        },
        `"vmGalleryImagePublisher`": {
            `"type`": `"string`",
            `"metadata`": {
                `"description`": `"(Required when vmImageType = Gallery) Gallery image Publisher.`"
            },
            `"defaultValue`": `"`"
        },
        `"vmGalleryImageSKU`": {
            `"type`": `"string`",
            `"metadata`": {
                `"description`": `"(Required when vmImageType = Gallery) Gallery image SKU.`"
            },
            `"defaultValue`": `"`"
        },
        `"vmImageVhdUri`": {
            `"type`": `"string`",
            `"metadata`": {
                `"description`": `"(Required when vmImageType = CustomVHD) URI of the sysprepped image vhd file to be used to create the session host VMs. For example, https://rdsstorage.blob.core.windows.net/vhds/sessionhostimage.vhd`"
            },
            `"defaultValue`": `"`"
        },
        `"vmCustomImageSourceId`": {
            `"type`": `"string`",
            `"metadata`": {
                `"description`": `"(Required when vmImageType = CustomImage) Resource ID of the image`"
            },
            `"defaultValue`": `"`"
        },
        `"vmDiskType`": {
            `"type`": `"string`",
            `"allowedValues`": [
                `"UltraSSD_LRS`",
                `"Premium_LRS`",
                `"StandardSSD_LRS`",
                `"Standard_LRS`"
            ],
            `"metadata`": {
                `"description`": `"The VM disk type for the VM: HDD or SSD.`"
            }
        },
        `"vmUseManagedDisks`": {
            `"type`": `"bool`",
            `"metadata`": {
                `"description`": `"True indicating you would like to use managed disks or false indicating you would like to use unmanaged disks.`"
            }
        },
        `"storageAccountResourceGroupName`": {
            `"type`": `"string`",
            `"metadata`": {
                `"description`": `"(Required when vmUseManagedDisks = False) The resource group containing the storage account of the image vhd file.`"
            },
            `"defaultValue`": `"`"
        },
        `"existingVnetName`": {
            `"type`": `"string`",
            `"metadata`": {
                `"description`": `"The name of the virtual network the VMs will be connected to.`"
            }
        },
        `"existingSubnetName`": {
            `"type`": `"string`",
            `"metadata`": {
                `"description`": `"The subnet the VMs will be placed in.`"
            }
        },
        `"virtualNetworkResourceGroupName`": {
            `"type`": `"string`",
            `"metadata`": {
                `"description`": `"The resource group containing the existing virtual network.`"
            }
        },
        `"createNetworkSecurityGroup`": {
            `"type`": `"bool`",
            `"metadata`": {
                `"description`": `"Whether to create a new network security group or use an existing one`"
            },
            `"defaultValue`": false
        },
        `"networkSecurityGroupId`": {
            `"type`": `"string`",
            `"metadata`": {
                `"description`": `"The resource id of an existing network security group`"
            },
            `"defaultValue`": `"`"
        },
        `"networkSecurityGroupRules`": {
            `"type`": `"array`",
            `"metadata`": {
                `"description`": `"The rules to be given to the new network security group`"
            },
            `"defaultValue`": []
        },
        `"availabilitySetTags`": {
            `"type`": `"object`",
            `"metadata`": {
                `"description`": `"The tags to be assigned to the availability set`"
            },
            `"defaultValue`": {}
        },
        `"networkInterfaceTags`": {
            `"type`": `"object`",
            `"metadata`": {
                `"description`": `"The tags to be assigned to the network interfaces`"
            },
            `"defaultValue`": {}
        },
        `"networkSecurityGroupTags`": {
            `"type`": `"object`",
            `"metadata`": {
                `"description`": `"The tags to be assigned to the network security groups`"
            },
            `"defaultValue`": {}
        },
        `"virtualMachineTags`": {
            `"type`": `"object`",
            `"metadata`": {
                `"description`": `"The tags to be assigned to the virtual machines`"
            },
            `"defaultValue`": {}
        },
        `"imageTags`": {
            `"type`": `"object`",
            `"metadata`": {
                `"description`": `"The tags to be assigned to the images`"
            },
            `"defaultValue`": {}
        },
        `"deploymentId`": {
            `"type`": `"string`",
            `"metadata`": {
                `"description`": `"GUID for the deployment`"
            },
            `"defaultValue`": `"`"
        },
        `"apiVersion`": {
            `"type`": `"string`",
            `"metadata`": {
                `"description`": `"WVD api version`"
            },
            `"defaultValue`": `"2019-12-10-preview`"
        },
        `"ouPath`": {
            `"type`": `"string`",
            `"metadata`": {
                `"description`": `"OUPath for the domain join`"
            },
            `"defaultValue`": `"`"
        },
        `"domain`": {
            `"type`": `"string`",
            `"metadata`": {
                `"description`": `"Domain to join`"
            },
            `"defaultValue`": `"`"
        },
        `"aadJoin`": {
            `"type`": `"bool`",
            `"metadata`": {
                `"description`": `"IMPORTANT: Please don't use this parameter as AAD Join is not supported yet. True if AAD Join, false if AD join`"
            },
            `"defaultValue`": false
        },
        `"intune`": {
            `"type`": `"bool`",
            `"metadata`": {
                `"description`": `"IMPORTANT: Please don't use this parameter as intune enrollment is not supported yet. True if intune enrollment is selected.  False otherwise`"
            },
            `"defaultValue`": false
        }
    },
    `"variables`": {
        `"rdshManagedDisks`": `"[if(equals(parameters('vmImageType'), 'CustomVHD'), parameters('vmUseManagedDisks'), bool('true'))]`",
        `"rdshPrefix`": `"[concat(parameters('vmNamePrefix'),'-')]`",
        `"avSetSKU`": `"[if(variables('rdshManagedDisks'), 'Aligned', 'Classic')]`",
        `"vhds`": `"[concat('vhds','/', variables('rdshPrefix'))]`",
        `"subnet-id`": `"[resourceId(parameters('virtualNetworkResourceGroupName'),'Microsoft.Network/virtualNetworks/subnets',parameters('existingVnetName'), parameters('existingSubnetName'))]`",
        `"vmTemplateName`": `"[concat( if(variables('rdshManagedDisks'), 'managedDisks', 'unmanagedDisks'), '-', toLower(replace(parameters('vmImageType'),' ', '')), 'vm')]`",
        `"vmTemplateUri`": `"[concat(parameters('nestedTemplatesLocation'), variables('vmTemplateName'),'.json')]`",
        `"rdshVmNamesOutput`": {
            `"copy`": [
                {
                    `"name`": `"rdshVmNamesCopy`",
                    `"count`": `"[parameters('vmNumberOfInstances')]`",
                    `"input`": {
                        `"name`": `"[concat(variables('rdshPrefix'), add(parameters('vmInitialNumber'), copyIndex('rdshVmNamesCopy')))]`"
                    }
                }
            ]
        }
    },
    `"resources`": [
        {
            `"apiVersion`": `"2018-05-01`",
            `"name`": `"[concat('UpdateHostPool-', parameters('deploymentId'))]`",
            `"type`": `"Microsoft.Resources/deployments`",
            `"resourceGroup`": `"[parameters('hostpoolResourceGroup')]`",
            `"condition`": `"[not(empty(parameters('hostpoolResourceGroup')))]`",
            `"properties`": {
                `"mode`": `"Incremental`",
                `"template`": {
                    `"`$schema`": `"https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#`",
                    `"contentVersion`": `"1.0.0.0`",
                    `"resources`": [
                        {
                            `"name`": `"[parameters('hostpoolName')]`",
                            `"apiVersion`": `"[parameters('apiVersion')]`",
                            `"location`": `"[parameters('hostpoolLocation')]`",
                            `"type`": `"Microsoft.DesktopVirtualization/hostpools`",
                            `"properties`": `"[parameters('hostpoolProperties')]`"
                        }
                    ]
                }
            }
        },
        {
            `"apiVersion`": `"2018-05-01`",
            `"name`": `"[concat('AVSet-linkedTemplate-', parameters('deploymentId'))]`",
            `"type`": `"Microsoft.Resources/deployments`",
            `"resourceGroup`": `"[parameters('vmResourceGroup')]`",
            `"condition`": `"[and(equals(parameters('availabilityOption'), 'AvailabilitySet'), parameters('createAvailabilitySet'))]`",
            `"properties`": {
                `"mode`": `"Incremental`",
                `"template`": {
                    `"`$schema`": `"https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#`",
                    `"contentVersion`": `"1.0.0.0`",
                    `"resources`": [
                        {
                            `"apiVersion`": `"2018-10-01`",
                            `"type`": `"Microsoft.Compute/availabilitySets`",
                            `"name`": `"[parameters('availabilitySetName')]`",
                            `"location`": `"[parameters('vmLocation')]`",
                            `"tags`": `"[parameters('availabilitySetTags')]`",
                            `"properties`": {
                                `"platformUpdateDomainCount`": `"[parameters('availabilitySetUpdateDomainCount')]`",
                                `"platformFaultDomainCount`": `"[parameters('availabilitySetFaultDomainCount')]`"
                            },
                            `"sku`": {
                                `"name`": `"[variables('avSetSKU')]`"
                            }
                        }
                    ]
                }
            },
            `"dependsOn`": [
                `"[concat('UpdateHostPool-', parameters('deploymentId'))]`"
            ]
        },
        {
            `"apiVersion`": `"2018-05-01`",
            `"name`": `"[concat('vmCreation-linkedTemplate-', parameters('deploymentId'))]`",
            `"resourceGroup`": `"[parameters('vmResourceGroup')]`",
            `"dependsOn`": [
                `"[concat('AVSet-linkedTemplate-', parameters('deploymentId'))]`"
            ],
            `"type`": `"Microsoft.Resources/deployments`",
            `"properties`": {
                `"mode`": `"Incremental`",
                `"templateLink`": {
                    `"uri`": `"[variables('vmTemplateUri')]`",
                    `"contentVersion`": `"1.0.0.0`"
                },
                `"parameters`": {
                    `"artifactsLocation`": {
                        `"value`": `"[parameters('artifactsLocation')]`"
                    },
                    `"availabilityOption`": {
                        `"value`": `"[parameters('availabilityOption')]`"
                    },
                    `"availabilitySetName`": {
                        `"value`": `"[parameters('availabilitySetName')]`"
                    },
                    `"availabilityZone`": {
                        `"value`": `"[parameters('availabilityZone')]`"
                    },
                    `"vmImageVhdUri`": {
                        `"value`": `"[parameters('vmImageVhdUri')]`"
                    },
                    `"storageAccountResourceGroupName`": {
                        `"value`": `"[parameters('storageAccountResourceGroupName')]`"
                    },
                    `"vmGalleryImageOffer`": {
                        `"value`": `"[parameters('vmGalleryImageOffer')]`"
                    },
                    `"vmGalleryImagePublisher`": {
                        `"value`": `"[parameters('vmGalleryImagePublisher')]`"
                    },
                    `"vmGalleryImageSKU`": {
                        `"value`": `"[parameters('vmGalleryImageSKU')]`"
                    },
                    `"rdshPrefix`": {
                        `"value`": `"[variables('rdshPrefix')]`"
                    },
                    `"rdshNumberOfInstances`": {
                        `"value`": `"[parameters('vmNumberOfInstances')]`"
                    },
                    `"rdshVMDiskType`": {
                        `"value`": `"[parameters('vmDiskType')]`"
                    },
                    `"rdshVmSize`": {
                        `"value`": `"[parameters('vmSize')]`"
                    },
                    `"enableAcceleratedNetworking`": {
                        `"value`": false
                    },
                    `"vmAdministratorAccountUsername`": {
                        `"value`": `"[parameters('vmAdministratorAccountUsername')]`"
                    },
                    `"vmAdministratorAccountPassword`": {
                        `"value`": `"[parameters('vmAdministratorAccountPassword')]`"
                    },
                    `"administratorAccountUsername`": {
                        `"value`": `"[parameters('administratorAccountUsername')]`"
                    },
                    `"administratorAccountPassword`": {
                        `"value`": `"[parameters('administratorAccountPassword')]`"
                    },
                    `"subnet-id`": {
                        `"value`": `"[variables('subnet-id')]`"
                    },
                    `"vhds`": {
                        `"value`": `"[variables('vhds')]`"
                    },
                    `"rdshImageSourceId`": {
                        `"value`": `"[parameters('vmCustomImageSourceId')]`"
                    },
                    `"location`": {
                        `"value`": `"[parameters('vmLocation')]`"
                    },
                    `"createNetworkSecurityGroup`": {
                        `"value`": `"[parameters('createNetworkSecurityGroup')]`"
                    },
                    `"networkSecurityGroupId`": {
                        `"value`": `"[parameters('networkSecurityGroupId')]`"
                    },
                    `"networkSecurityGroupRules`": {
                        `"value`": `"[parameters('networkSecurityGroupRules')]`"
                    },
                    `"networkInterfaceTags`": {
                        `"value`": `"[parameters('networkInterfaceTags')]`"
                    },
                    `"networkSecurityGroupTags`": {
                        `"value`": `"[parameters('networkSecurityGroupTags')]`"
                    },
                    `"virtualMachineTags`": {
                        `"value`": `"[parameters('virtualMachineTags')]`"
                    },
                    `"imageTags`": {
                        `"value`": `"[parameters('imageTags')]`"
                    },
                    `"vmInitialNumber`": {
                        `"value`": `"[parameters('vmInitialNumber')]`"
                    },
                    `"hostpoolName`": {
                        `"value`": `"[parameters('hostpoolName')]`"
                    },
                    `"hostpoolToken`": {
                        `"value`": `"[parameters('hostpoolToken')]`"
                    },
                    `"domain`": {
                        `"value`": `"[parameters('domain')]`"
                    },
                    `"ouPath`": {
                        `"value`": `"[parameters('ouPath')]`"
                    },
                    `"aadJoin`": {
                        `"value`": `"[parameters('aadJoin')]`"
                    },
                    `"intune`": {
                        `"value`": `"[parameters('intune')]`"
                    },
                    `"_guidValue`": {
                        `"value`": `"[parameters('deploymentId')]`"
                    }
                }
            }
        }
    ],
    `"outputs`": {
        `"rdshVmNamesObject`": {
            `"value`": `"[variables('rdshVmNamesOutput')]`",
            `"type`": `"object`"
        }
    }
}"

$templatefile > ./templatefile.json


#Create session host VM
New-AzResourceGroupDeployment -name "$existingWVDHostPoolName-$vmNamePrefix" -ResourceGroupName "$resourceGroupName" -TemplateParameterFile ./paramfile.json -TemplateFile ./templatefile.json

$vmnamefull=$vmNamePrefix+"-0.uapcld.net"

#Checking if the VM is available
[int]$counter = 10
while ( ($counter -gt 0 ) -AND (Get-AzWvdSessionHost -ResourceGroupName $resourceGroupName -HostPoolName $existingWVDHostPoolName -Name $vmnamefull -ErrorAction silentlycontinue).status -ne 'Available') { write-output("$vmnamefull currently Unavailable so Sleeping $counter");start-sleep -s 30 ; $counter--;
if ($counter -EQ 0) {write-output("waited too long for VM session host Availability so exiting");Exit}}


Update-AzWvdSessionHost -HostPoolName $existingWVDHostPoolName -Name $vmnamefull -ResourceGroupName $resourceGroupName -AllowNewSession:$False 
