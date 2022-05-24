param ([Parameter(Mandatory)] $ResourceGroupName,[Parameter(Mandatory)] $location,[Parameter(Mandatory)] $vmName)
Add-Type -AssemblyName System.Web
#Connect to Azure using service principal
.\ConnectAZAccount-nhi-iac-uap-dev-sp.ps1
#Set parameters Examples
#$location='eastus2'
#$resourceGroupName="phx-wvd-rg-dev"

$templatefileextension="{
    `"`$schema`": `"https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#`",
    `"contentVersion`": `"1.0`",
    `"parameters`": {
        `"vmName`":{
            `"type`": `"string`",
            `"metadata`": {
                `"Description`": `"VM name`"
            }
        },
        `"vmLocation`": {
            `"type`": `"string`",
            `"metadata`": {
                `"description`": `"The location of the session host VMs.`"
            }
        }
    },
    `"variables`": {},
    `"resources`": [
        {
            `"type`": `"Microsoft.Compute/virtualMachines/extensions`",
            `"name`": `"[concat(parameters('vmName'), '`/DependencyAgent')]`",
            `"apiVersion`": `"2017-03-30`",
            `"location`": `"[parameters('vmLocation')]`",
            `"properties`": {
                `"publisher`": `"Microsoft.Azure.Monitoring.DependencyAgent`",
                `"type`": `"DependencyAgentWindows`",
                `"typeHandlerVersion`": `"9.3`",
                `"autoUpgradeMinorVersion`": true
            }
        }
    ],`"outputs`": {}
}"

$templatefileextension > ./templatefileextension.json

$deployname='DependencyAgent'+$vmName
New-AzResourceGroupDeployment -Name $deployname -ResourceGroupName $ResourceGroupName -TemplateFile ".\templatefileextension.json" -vmName $vmName -vmLocation $location



$templatefilevaextension="{
    `"`$schema`": `"https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#`",
    `"contentVersion`": `"1.0.0.0`",
    `"parameters`": {
        `"vmName`": {
            `"type`": `"String`"
        },
        `"apiVersionByEnv`": {
            `"type`": `"String`"
        }
    },
    `"resources`": [
        {
            `"type`": `"Microsoft.Compute/virtualMachines/providers/serverVulnerabilityAssessments`",
            `"apiVersion`": `"[parameters('apiVersionByEnv')]`",
            `"name`": `"[concat(parameters('vmName'), '/Microsoft.Security/default')]`"
        }
    ]
}"

$templatefilevaextension > ./templatefilevaextension.json

$deployname='serverVulnerabilityAssessments'+$vmName
New-AzResourceGroupDeployment -Name $deployname -ResourceGroupName $ResourceGroupName -TemplateFile ".\templatefilevaextension.json" -vmName $vmName -apiVersionByEnv '2015-06-01-preview'



$templatefilevaextension="{
    `"`$schema`": `"http://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#`",
    `"contentVersion`": `"1.0.0.0`",
    `"parameters`": {
        `"vmName`": {
            `"type`": `"String`"
        },
        `"vmLocation`": {
            `"type`": `"String`"
        },
        `"ExclusionsPaths`": {
            `"defaultValue`": `"`",
            `"type`": `"String`",
            `"metadata`": {
                `"description`": `"Semicolon delimited list of file paths or locations to exclude from scanning`"
            }
        },
        `"ExclusionsExtensions`": {
            `"defaultValue`": `"`",
            `"type`": `"String`",
            `"metadata`": {
                `"description`": `"Semicolon delimited list of file extensions to exclude from scanning`"
            }
        },
        `"ExclusionsProcesses`": {
            `"defaultValue`": `"`",
            `"type`": `"String`",
            `"metadata`": {
                `"description`": `"Semicolon delimited list of process names to exclude from scanning`"
            }
        },
        `"RealtimeProtectionEnabled`": {
            `"defaultValue`": `"true`",
            `"type`": `"String`",
            `"metadata`": {
                `"description`": `"Indicates whether or not real time protection is enabled (default is true)`"
            }
        },
        `"ScheduledScanSettingsIsEnabled`": {
            `"defaultValue`": `"false`",
            `"type`": `"String`",
            `"metadata`": {
                `"description`": `"Indicates whether or not custom scheduled scan settings are enabled (default is false)`"
            }
        },
        `"ScheduledScanSettingsScanType`": {
            `"defaultValue`": `"Quick`",
            `"type`": `"String`",
            `"metadata`": {
                `"description`": `"Indicates whether scheduled scan setting type is set to Quick or Full (default is Quick)`"
            }
        },
        `"ScheduledScanSettingsDay`": {
            `"defaultValue`": `"7`",
            `"type`": `"String`",
            `"metadata`": {
                `"description`": `"Day of the week for scheduled scan (1-Sunday, 2-Monday, ..., 7-Saturday)`"
            }
        },
        `"ScheduledScanSettingsTime`": {
            `"defaultValue`": `"120`",
            `"type`": `"String`",
            `"metadata`": {
                `"description`": `"When to perform the scheduled scan, measured in minutes from midnight (0-1440). For example: 0 = 12AM, 60 = 1AM, 120 = 2AM.`"
            }
        }
    },
    `"resources`": [
        {
            `"type`": `"Microsoft.Compute/virtualMachines/extensions`",
            `"apiVersion`": `"2015-06-15`",
            `"name`": `"[concat(parameters('vmName'),'/IaaSAntimalware')]`",
            `"location`": `"[parameters('vmLocation')]`",
            `"properties`": {
                `"publisher`": `"Microsoft.Azure.Security`",
                `"type`": `"IaaSAntimalware`",
                `"typeHandlerVersion`": `"1.3`",
                `"autoUpgradeMinorVersion`": true,
                `"settings`": {
                    `"AntimalwareEnabled`": true,
                    `"RealtimeProtectionEnabled`": `"[parameters('RealtimeProtectionEnabled')]`",
                    `"ScheduledScanSettings`": {
                        `"isEnabled`": `"[parameters('ScheduledScanSettingsIsEnabled')]`",
                        `"day`": `"[parameters('ScheduledScanSettingsDay')]`",
                        `"time`": `"[parameters('ScheduledScanSettingsTime')]`",
                        `"scanType`": `"[parameters('ScheduledScanSettingsScanType')]`"
                    },
                    `"Exclusions`": {
                        `"Extensions`": `"[parameters('ExclusionsExtensions')]`",
                        `"Paths`": `"[parameters('ExclusionsPaths')]`",
                        `"Processes`": `"[parameters('ExclusionsProcesses')]`"
                    }
                }
            }
        }
    ]
}"
$templatefilevaextension > ./templatefilevaextension.json
$deployname='microsoftantimalware'+$vmName
New-AzResourceGroupDeployment -Name $deployname -ResourceGroupName $ResourceGroupName -TemplateFile ".\templatefilevaextension.json" -vmName $vmName -vmLocation $location -exclusionsPaths "" -exclusionsExtensions "" -exclusionsProcesses "" -realtimeProtectionEnabled "true" -scheduledScanSettingsIsEnabled "true" -scheduledScanSettingsScanType "Quick" -scheduledScanSettingsDay "0" -scheduledScanSettingsTime "120"
