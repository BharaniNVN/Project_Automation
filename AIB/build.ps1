param ([Parameter(Mandatory)] $ARM_SUBSCRIPTION_ID,[Parameter(Mandatory)] $ARM_CLIENT_ID,[Parameter(Mandatory)] $ARM_CLIENT_SECRET,[Parameter(Mandatory)] $ARM_TENANT_ID)
try
{
$ErrorActionPreference = "Stop"
write-output("subscription id is $SUBSCRIPTION_ID")
$PWord = ConvertTo-SecureString -String $CLIENT_SECRET -AsPlainText -Force
$Creds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $ARM_CLIENT_ID, $PWord
'Az.Accounts','Az.Resources','Az.ImageBuilder', 'Az.ManagedServiceIdentity', 'Az.Compute', 'Az.Storage' | ForEach-Object {Install-Module -Name $_ -AllowPrerelease -Force}
Connect-AzAccount -Credential $Creds -Tenant $ARM_TENANT_ID -ServicePrincipal
write-output("Build Step")

$file = Import-Csv -Path ./imagestobuild.txt -delimiter '|'
foreach ( $i in $file )
 { 
    $templateFilePath = "./InputTemplates/"
    $templateFileName=$i.ARMTEMPLATEFILENAME
    $templateFileNameOutput="output_$templateFileName"
    if (-not(Test-Path -Path $templateFilePath/$templateFileName -PathType Leaf)) 
    {
     write-output("ARM Template file $templateFilePath/$templateFileName is missing, So Exiting`r`n")
     exit
    }
    cp $templateFilePath/$templateFileName $templateFilePath/$templateFileNameOutput
    
    $ARMTEMPLATEPARAMFILE=$i.ARMTEMPLATEPARAMFILE
    if (-not(Test-Path -Path $templateFilePath/$ARMTEMPLATEPARAMFILE -PathType Leaf)) 
    {
     write-output("ARM Template param file $templateFilePath/$ARMTEMPLATEPARAMFILE is missing, So Exiting`r`n")
     exit
    }
write-output("Now starting build for template file $templateFilePath/$templateFileName using param file $templateFilePath/$ARMTEMPLATEPARAMFILE`r`n")
if ($i.BUILDFLAG -eq "Y")
{
$subscriptionID = (Get-AzContext).Subscription.Id
$imageResourceGroup = ''
$location = (Get-AzResourceGroup -Name $imageResourceGroup).Location
# user-assigned managed identity
$identityName = (Get-AzUserAssignedIdentity -ResourceGroupName $imageResourceGroup).Name
# get the user assigned managed identity id
$identityNameResourceId = (Get-AzUserAssignedIdentity -ResourceGroupName $imageResourceGroup -Name $identityName).Id


. $templateFilePath/$ARMTEMPLATEPARAMFILE
$context = (Get-AzStorageAccount -ResourceGroupName $imageResourceGroup -AccountName 'phxaibsoftwarereposadev').context

$sastoken=New-AzStorageAccountSASToken -Context $context -Service Blob -ResourceType Service,Container,Object -Permission "racwdlup"
#write-output("Sas token is ")
#write-output("$sastoken")

#write-output("$sigGalleryName")
((Get-Content -path $templateFilePath/$templateFileNameOutput -Raw) -replace '<buildTimeoutInMinutes>',$buildTimeoutInMinutes) | Set-Content -Path $templateFilePath/$templateFileNameOutput
((Get-Content -path $templateFilePath/$templateFileNameOutput -Raw) -replace '<vmSize>',$vmSize) | Set-Content -Path $templateFilePath/$templateFileNameOutput
((Get-Content -path $templateFilePath/$templateFileNameOutput -Raw) -replace '<osDiskSizeGB>',$osDiskSizeGB) | Set-Content -Path $templateFilePath/$templateFileNameOutput
((Get-Content -path $templateFilePath/$templateFileNameOutput -Raw) -replace '<subscriptionID>',$subscriptionID) | Set-Content -Path $templateFilePath/$templateFileNameOutput
((Get-Content -path $templateFilePath/$templateFileNameOutput -Raw) -replace '<rgName>',$imageResourceGroup) | Set-Content -Path $templateFilePath/$templateFileNameOutput
((Get-Content -path $templateFilePath/$templateFileNameOutput -Raw) -replace '<region>',$location) | Set-Content -Path $templateFilePath/$templateFileNameOutput
((Get-Content -path $templateFilePath/$templateFileNameOutput -Raw) -replace '<imgBuilderId>',$identityNameResourceId) | Set-Content -Path $templateFilePath/$templateFileNameOutput
((Get-Content -path $templateFilePath/$templateFileNameOutput -Raw) -replace '<PUBLISHER>',$PUBLISHER) | Set-Content -Path $templateFilePath/$templateFileNameOutput
((Get-Content -path $templateFilePath/$templateFileNameOutput -Raw) -replace '<OFFER>',$OFFER) | Set-Content -Path $templateFilePath/$templateFileNameOutput
((Get-Content -path $templateFilePath/$templateFileNameOutput -Raw) -replace '<SKU>',$SKU) | Set-Content -Path $templateFilePath/$templateFileNameOutput
((Get-Content -path $templateFilePath/$templateFileNameOutput -Raw) -replace '<sharedImageGalName>',$sigGalleryName) | Set-Content -Path $templateFilePath/$templateFileNameOutput
((Get-Content -path $templateFilePath/$templateFileNameOutput -Raw) -replace '<sigImageDefName>',$sigImageDefName) | Set-Content -Path $templateFilePath/$templateFileNameOutput
#((Get-Content -path $templateFilePath/$templateFileNameOutput -Raw) -replace '<sigImageVersion>',$sigImageVersion) | Set-Content -Path $templateFilePath/$templateFileNameOutput
((Get-Content -path $templateFilePath/$templateFileNameOutput -Raw) -replace '<runOutputName>',$runOutputName) | Set-Content -Path $templateFilePath/$templateFileNameOutput
((Get-Content -path $templateFilePath/$templateFileNameOutput -Raw) -replace '<artifactTags_source>',$artifactTags_source) | Set-Content -Path $templateFilePath/$templateFileNameOutput
((Get-Content -path $templateFilePath/$templateFileNameOutput -Raw) -replace '<artifactTags_baseosimg>',$artifactTags_baseosimg) | Set-Content -Path $templateFilePath/$templateFileNameOutput
((Get-Content -path $templateFilePath/$templateFileNameOutput -Raw) -replace '<region1>',$location) | Set-Content -Path $templateFilePath/$templateFileNameOutput
((Get-Content -path $templateFilePath/$templateFileNameOutput -Raw) -replace '<vnetRgName>',$vnetRgName) | Set-Content -Path $templateFilePath/$templateFileNameOutput
((Get-Content -path $templateFilePath/$templateFileNameOutput -Raw) -replace '<vnetName>',$vnetName) | Set-Content -Path $templateFilePath/$templateFileNameOutput
((Get-Content -path $templateFilePath/$templateFileNameOutput -Raw) -replace '<subnetName>',$subnetName) | Set-Content -Path $templateFilePath/$templateFileNameOutput
((Get-Content -path $templateFilePath/$templateFileNameOutput -Raw) -replace '<sastoken>',$sastoken) | Set-Content -Path $templateFilePath/$templateFileNameOutput

cat ./InputTemplates/$templateFileNameOutput


$ImageTemplateStatus=Get-AzImageBuilderTemplate -ResourceGroupName $imageResourceGroup|where-Object {$_.Name -eq "$imageTemplateName"}

if (($ImageTemplateStatus.Name -eq "$imageTemplateName")) 
{
write-output "Image template $imageTemplateName Already Exists, So deleting it and recreating`r`n"
remove-AzImageBuilderTemplate -ImageTemplateName $imageTemplateName -ResourceGroupName $imageResourceGroup
write-output "Image template $imageTemplateName Deleted."
}



#Create a new Image Definition in Shared Image Gallery if does not exists

$sigImageDefNameStatus=Get-AzGalleryImageDefinition -ResourceGroupName $imageResourceGroup -GalleryName $sigGalleryName|where-Object {$_.Name -eq "$sigImageDefName"}
write-output("sigImageDefNameStatus.Name is $sigImageDefNameStatus.Name")
write-output("$sigImageDefName is $sigImageDefName")
$PUBLISHERNEW = $PUBLISHER + $sigImageDefName
if (($sigImageDefNameStatus.Name -ne "$sigImageDefName") -And ($sigImageDefName -ne "")) 
{
$GalleryParams = @{
    GalleryName = $sigGalleryName
    ResourceGroupName = $imageResourceGroup
    Location = $location
    Name = $sigImageDefName
    OsState = 'generalized'
    OsType = $OsType
    Publisher = $PUBLISHERNEW
    Offer = $OFFER
    Sku = $Sku
  }
New-AzGalleryImageDefinition @GalleryParams
}

#Creating image template
write-output "Now creating Image template $imageTemplateName`r`n"
New-AzResourceGroupDeployment -ResourceGroupName $imageResourceGroup -TemplateFile $templateFilePath/$templateFileNameOutput `
 -api-version "2020-02-14" -imageTemplateName $imageTemplateName -svclocation $location

#Creating an image
write-output("Building Image $imageTemplateName")
Start-AzImageBuilderTemplate -ResourceGroupName $imageResourceGroup -Name $imageTemplateName
}
else {
    write-output("For template file $templateFileName flag is not set to Y in imagestobuild.txt file, So not building the image for template $templateFileName`r`n")
    write-output("now building next image`r`n")
}
 }
}
catch
{
$ErrorMessage = $_.Exception.Message
$FailedItem = $_.Exception.ItemName
write-output ("$FailedItem with message $ErrorMessage")
}
