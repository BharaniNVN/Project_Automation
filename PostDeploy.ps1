<# List of Project Shares#>
$projectshares = 
<#List of Common Shares or Code Repo's #>
$commonshares = 


# Initialize and Format the disks attached

$disks = Get-Disk | where partitionstyle -eq 'raw' | sort number
$Currentdriveletters = (Get-Volume | Select DriveLetter | Sort-Object DriveLetter).DriveLetter
$Currentdriveletters_num = $Currentdriveletters | ForEach-Object {[int][char]$_}

$CurrentVolumelabels = ((Get-Volume | Select FileSystemLabel).FileSystemLabel) | ?{$_ -ne ""}


#$letters = 70..89 | ForEach-Object {[char]$_}

$labelsfilter = "Temporary Storage","System Reserved","Windows","SES","DOD","ZIP5","Code Repository", "Software Share","NHI DATA","NHI HomeDrive","state","rzip5","rpccv"

$labelsToBeAdded = Compare-Object -DifferenceObject $labelsfilter -ReferenceObject $CurrentVolumelabels -PassThru

$count = 0

foreach ($disk in $disks) {

    $driveletter_nextnum = ($Currentdriveletters_num[$Currentdriveletters_num.Count - 1] + 1)
    $Currentdriveletters_num += $driveletter_nextnum

    $driveLetter = [char]$driveletter_nextnum
    $disk |
    Initialize-Disk -PartitionStyle MBR -PassThru |
    New-Partition -UseMaximumSize -DriveLetter $driveLetter |
    Format-Volume -FileSystem NTFS -NewFileSystemLabel $labelsToBeAdded[$count] -Confirm:$false -Force
	$count++
} 


foreach ($projectshare in $projectshares){

$view_name = $projectshare.Split("_")

$vol_info = Get-Volume -FileSystemLabel $view_name[1]

$driveletter = $vol_info.DriveLetter

$drivepath = "$driveletter" + ":\"

$folderPath = "$drivepath" + "$projectshare"

$identity = "" + "" + "$projectshare" + "_DEV"
#$identity2 = "$env:COMPUTERNAME" + "\AD_" + "$projectshare" + "_USERS"

if (!(Test-Path $folderPath)){
     
        
       # $identity1 = "uapcld" + "$projectshare" + "_OWNERS"
       # $identity2 = "uapcld" + "$projectshare" + "_USERS"

        


        New-Item -Name $projectshare -ItemType directory -Path "$drivepath"

        New-SmbShare -Name $projectshare -Path $folderPath

        $checkPermissions = Get-SmbShareAccess -Name $projectshare | Select AccountName

        if(!($checkPermissions.AccountName -contains $identity)){
        
            Grant-SmbShareAccess -Name $projectshare -AccountName $identity -AccessRight Change -Force
            Revoke-SmbShareAccess -Name $projectshare -AccountName "Everyone" -Force
            Write-Host ("I'm in Check permissions if loop")
        }

        #Grant-SmbShareAccess -Name $projectshare -AccountName $identity -AccessRight Change -Force
        
        #Grant-SmbShareAccess -Name $projectshare -AccountName $identity2 -AccessRight Read -Force

        #$permissions = "CreateDirectories, AppendData, ReadExtendedAttributes, WriteExtendedAttributes, ExecuteFile, ReadAttributes, WriteAttributes, ReadPermissions, Synchronize"
        $right1 = "CreateDirectories, AppendData, ReadExtendedAttributes, WriteExtendedAttributes, ExecuteFile, ReadAttributes, WriteAttributes, ReadPermissions, Synchronize"
        #$right2 = "Read"
        $inheritence = "ContainerInherit, ObjectInherit"
        $propagation = "None"
        $type = "Allow"

        #Create a Permission
        $ACE1 = New-Object System.Security.AccessControl.FileSystemAccessRule($identity,$right1,$inheritence,$propagation,$type)      

        #Get the Current Access Control List (Permissions) 
        $Acl = Get-Acl -Path $folderPath

        #Add the new permission
        $Acl.AddAccessRule($ACE1)

       #Assign the Updated Access Control List to the Folder Path
        Set-Acl -Path $folderPath -AclObject $Acl

        Write-Host("ACE1 is done")

        #$Acl = Get-Acl -Path $folderPath

        #$ACE2 = New-Object System.Security.AccessControl.FileSystemAccessRule($identity2,$right2,$inheritence,$propagation,$type)

        #$Acl.AddAccessRule($ACE2)

        #Set-Acl -Path $folderPath -AclObject $Acl 
        
        #Write-Host("ACE2 is done")      
    
    }

    else {
     $checkIfShared = Get-SmbShare -Name $projectshare

        if(!$checkIfShared){

            New-SmbShare -Name $projectshare -Path $folderPath
        }
        
        $checkPermissions = Get-SmbShareAccess -Name $projectshare | Select AccountName

        if(!($checkPermissions.AccountName -contains $identity)){
        
            Grant-SmbShareAccess -Name $projectshare -AccountName $identity -AccessRight Change -Force
            Write-Host ("I'm in Check permissions if loop")
        }

        <#if(! $checkPermissions.AccountName -contains $identity2){
        
           Grant-SmbShareAccess -Name $projectshare -AccountName $identity2 -AccessRight Read -Force
        }#>

        $right1 = "CreateDirectories, AppendData, ReadExtendedAttributes, WriteExtendedAttributes, ExecuteFile, ReadAttributes, WriteAttributes, ReadPermissions, Synchronize"
        $right2 = "Read"
        $inheritence = "ContainerInherit, ObjectInherit"
        $propagation = "None"
        $type = "Allow"
        $ACE1 = New-Object System.Security.AccessControl.FileSystemAccessRule($identity,$right1,$inheritence,$propagation,$type)      

        $Acl = Get-Acl -Path $folderPath

        $Acl.AddAccessRule($ACE1)

        Set-Acl -Path $folderPath -AclObject $Acl

        Write-Host("ACE1 is done")
<#
        $Acl = Get-Acl -Path $folderPath
        $ACE2 = New-Object System.Security.AccessControl.FileSystemAccessRule($identity2,$right2,$inheritence,$propagation,$type)
        $Acl.AddAccessRule($ACE2)
        Set-Acl -Path $folderPath -AclObject $Acl 
        
        Write-Host("ACE2 is done")    
        #>
}
}


foreach ($commonshare in $commonshares){

$commondirectory = "Code Repository"

$vol_info = Get-Volume -FileSystemLabel $commondirectory

$driveletter = $vol_info.DriveLetter

$drivepath = "$driveletter" + ":\"

$folderPath = "$drivepath" + "$commonshare"

$identity1 = "$env:COMPUTERNAME" + "$commonshare" + "_OWNER"
$identity2 = "$env:COMPUTERNAME" + "$commonshare" + "_USERS"

if (!(Test-Path $folderPath)){
     
        <#
        $identity1 = "uapcld" + "\AD_PHX" + "$projectshare" + "_OWNERS"
        $identity2 = "uapcld" + "\AD_PHX" + "$projectshare" + "_USERS"
        #>


        New-Item -Name $commonshare -ItemType directory -Path "$drivepath"

        New-SmbShare -Name $commonshare -Path $folderPath

        Grant-SmbShareAccess -Name $commonshare -AccountName $identity1 -AccessRight Change -Force
        
        Grant-SmbShareAccess -Name $commonshare -AccountName $identity2 -AccessRight Read -Force

           <# Removes the Default Read access to Everyone #>
        Revoke-SmbShareAccess -Name $commonshare -AccountName "Everyone" -Force
       
        $right1 = "CreateDirectories, AppendData, ReadExtendedAttributes, WriteExtendedAttributes, ExecuteFile, ReadAttributes, WriteAttributes, ReadPermissions, Synchronize"
        $right2 = "Read"
        $inheritence = "ContainerInherit, ObjectInherit"
        $propagation = "None"
        $type = "Allow"

        <# Create a Permission  #>
        $ACE1 = New-Object System.Security.AccessControl.FileSystemAccessRule($identity1,$right1,$inheritence,$propagation,$type)      

        <# Get the Current Access Control List (Permissions) #>
        $Acl = Get-Acl -Path $folderPath

        <# Add the new permission#>
        $Acl.AddAccessRule($ACE1)

        <# Assign the Updated Access Control List to the Folder Path#>
        Set-Acl -Path $folderPath -AclObject $Acl

        Write-Host("ACE1 is done")

        $Acl = Get-Acl -Path $folderPath

        $ACE2 = New-Object System.Security.AccessControl.FileSystemAccessRule($identity2,$right2,$inheritence,$propagation,$type)

        $Acl.AddAccessRule($ACE2)

        Set-Acl -Path $folderPath -AclObject $Acl 
        
        Write-Host("ACE2 is done")      
    
    }

    else {
     $checkIfShared = Get-SmbShare -Name $commonshare

        if(!$checkIfShared){

            New-SmbShare -Name $commonshare -Path $folderPath
            Revoke-SmbShareAccess -Name $commonshare -AccountName "Everyone" -Force
        }
        
        $checkPermissions = Get-SmbShareAccess -Name $projectshare | Select AccountName

        if(! $checkPermissions.AccountName -contains $identity1){
        
            Grant-SmbShareAccess -Name $commonshare -AccountName $identity1 -AccessRight Change -Force
        }

        if(! $checkPermissions.AccountName -contains $identity2){
        
           Grant-SmbShareAccess -Name $commonshare -AccountName $identity2 -AccessRight Read -Force
        }

        $right1 = "CreateDirectories, AppendData, ReadExtendedAttributes, WriteExtendedAttributes, ExecuteFile, ReadAttributes, WriteAttributes, ReadPermissions, Synchronize"
        $right2 = "Read"
        $inheritence = "ContainerInherit, ObjectInherit"
        $propagation = "None"
        $type = "Allow"
        $ACE1 = New-Object System.Security.AccessControl.FileSystemAccessRule($identity1,$right1,$inheritence,$propagation,$type)      

        $Acl = Get-Acl -Path $folderPath

        $Acl.AddAccessRule($ACE1)

        Set-Acl -Path $folderPath -AclObject $Acl

        Write-Host("ACE1 is done")

        $Acl = Get-Acl -Path $folderPath

        $ACE2 = New-Object System.Security.AccessControl.FileSystemAccessRule($identity2,$right2,$inheritence,$propagation,$type)

        $Acl.AddAccessRule($ACE2)

        Set-Acl -Path $folderPath -AclObject $Acl 
        
        Write-Host("ACE2 is done")    
}
}

<#  NHI HOME DRIVE Creation #>
$Letter = (Get-volume -FileSystemLabel "NHI HomeDrive" | select DriveLetter).DriveLetter
$Name = ""
$path = $Letter+":"
$folder = $Letter + ":" + "\" + $Name

if (!(Test-Path $folder))
{
New-Item -ItemType Directory -Path $path\$Name
New-SmbShare -name $Name$ -path $folder
Grant-SmbShareAccess -name $Name$ -AccountName "NT AUTHORITY\Authenticated Users" -AccessRight Full -Force
Revoke-SmbShareAccess -Name $Name$ -AccountName "Everyone" -Force
$permissions = 'AppendData','ReadAndExecute','ReadAttributes','ReadPermissions'
$ComputerAccount = ""
$acl = Get-Acl -Path $folder
$ace = New-Object Security.AccessControl.FileSystemAccessRule ($ComputerAccount, $permissions, 'None', 'None', 'Allow')
$acl.AddAccessRule($ace)
Set-Acl -AclObject $acl -Path $folder

}

else { Write-host "Folder Already Exists and It's shared as per the requiret"}



#<WS_Share_Details - Windows Shares creation>

$folders = 
$wvd_admin = 
$adGroup_ls_dev = 

#Remove-SmbShare -Name 'Ls_data_tools','lifescience','ls_common_share','lsrd_eor','lsrd_epi','lsrd_pas','lsrd_pi','lsrd_ram','lsrd_ram_ro','cdm','cmm','lsdat_common_share','mop','rwe','rwl','cmm_ro','cmm_rw','cdm_ro','cdm_rw','mop_ro','mop_rw','rwe_ro','rwe_rw','rwl_ro','rwl_rw'


function foldercreation
{
    param($folders)

    foreach ($folder in $folders) { 
    $folderarray = $folder.Split('-') 
    #Write-Host $folderarray.length
    $nhidirectory = "NHI DATA"

    $vol_info = Get-Volume -FileSystemLabel $nhidirectory

    $driveletter = $vol_info.DriveLetter
    $tempdtr = $driveLetter + ':'
    $tempdtr2 = $driveLetter + ':'
    $nhi_path = $tempdtr + ''
    $nhi_data_path = $tempdtr + '\'
    $nhi_share_name = 'NHI'

    if(!(Test-Path $nhi_path)){
        New-Item -Name $share_name -ItemType Directory -Path $data_path
        New-SmbShare -Name $share_name$ -Path $path
        Grant-SmbShareAccess -Name $share_name$ -AccountName "" -AccessRight Read -Force
        Revoke-SmbShareAccess -Name $share_name$ -AccountName "Everyone" -Force
        
        $permissions01 = "ReadAndExecute"
        $permissions02 = 'FullControl'
        $accountname = ""

        updateAcl $nhi_path $accountname $permissions01
        updateAcl $nhi_path $wvd_admin $permissions02
        

      }
    foreach ($dtr in $folderarray[0..($folderarray.length-1)]){

        if ($dtr -eq $folderarray[$folderarray.length - 1]){
        $tempdtr2 = $tempdtr2 + '\' + $dtr
        }
        else{
         $tempdtr = $tempdtr + '\' + $dtr
         $tempdtr2 = $tempdtr2 + '\' + $dtr
         }    
    }

    Write-Host ('$tempdtr2 is: ')
    Write-Host $tempdtr2

    if (!(Test-Path $tempdtr2)) {
        New-Item -Name $folderarray[-1] -ItemType Directory -Path $tempdtr
        #New-SmbShare -Name $folderarray[-1]$ -Path $tempdtr2
        #Grant-SmbShareAccess -Name $folderarray[-1] -AccountName "" -AccessRight Read -Force
        #Revoke-SmbShareAccess -Name $folderarray[-1] -AccountName "Everyone" -Force
    }else{}

    if ($folderarray -contains 'lifescience'){
    
    if($folderarray[-1] -eq 'lifescience'){
        $permissions01 = "ReadAndExecute"
        $permissions02 = 'FullControl'
        updateAcl $tempdtr2 $adGroup_ls_dev $permissions01
        updateAcl $tempdtr2 $wvd_admin $permissions02

    }
    elseif(($folderarray[-1] -eq 'ls_common_share') -or ($folderarray[-1] -eq 'lsrd_ram_ro')){
        $permissions01 = "ReadAndExecute"
        $permissions02 = 'FullControl'
        $permissions03 = 'Modify'
        $temp_split = $folderarray[-1].Split('_')
        
        $ad_Group = 'uapcld\azu_phx_sas_ls_'+ $temp_split[-2] + '_' + $temp_split[-1] +'_data'

        updateAcl $tempdtr2 $adGroup_ls_dev $permissions01
        updateAcl $tempdtr2 $wvd_admin $permissions02
        updateAcl $tempdtr2 $ad_Group $permissions03

    }
    else{
        $permissions02 = 'FullControl'
        $permissions01 = 'Modify'
        $temp_split = $folderarray[-1].Split('_')
        $ad_Group_otherfolder = '' + $temp_split[-1] + '_data'
        
        updateAcl $tempdtr2 $wvd_admin $permissions02
        updateAcl $tempdtr2 $ad_Group_otherfolder $permissions01

    }

    }
    elseif ($folderarray -contains '') {
    Write-Host $folderarray
    $temp_split = $folderarray[-1].Split('_')
    if(($temp_split[-1] -eq 'ro') -or ($temp_split[-1] -eq 'rw')){

    if($temp_split[-1] -eq 'ro'){
        $permissions01 = "ReadAndExecute"
        $permissions02 = 'FullControl'
        $permissions03 = 'Modify'
        $ad_Group = 'uapcld\azu_phx_sas_lsdat_' + $folderarray[-1] + '_data'
        $ad_Group_parentGroup = 'uapcld\azu_phx_sas_lsdat_' + $temp_split[-2] + '_data'

        Write-Host ('Parent AD group name is:')
        Write-Host $ad_Group
        Write-Host $adGroup_parentGroup

        updateAcl $tempdtr2 $ad_Group_parentGroup $permissions01
        updateAcl $tempdtr2 $wvd_admin $permissions02
        updateAcl $tempdtr2 $ad_Group $permissions03

    }
    else{
        $permissions01 = 'Modify'
        $permissions02 = 'FullControl'
        #$ad_Group = 'uapcld\azu_phx_sas_lsdat_' + $folderarray[-1] + '_data'
        $ad_Group_parentGroup = '' + $temp_split[-2] + '_data'
        #Write-Host $ad_Group
        Write-Host ('Parent AD group name is:')
        Write-Host $ad_Group_parentGroup
        updateAcl $tempdtr2 $ad_Group_parentGroup $permissions01
        updateAcl $tempdtr2 $wvd_admin $permissions02
        #updateAcl $tempdtr2 $ad_Group $permissions03

    }    
    }

    else{

    if($folderarray[-1] -eq ''){
        $permissions01 = "ReadAndExecute"
        $permissions02 = 'FullControl'
        updateAcl $tempdtr2 $adGroup_ls_dev $permissions01
        updateAcl $tempdtr2 $wvd_admin $permissions02

    }
    elseif($folderarray[-1] -eq ''){
        $permissions01 = "ReadAndExecute"
        $permissions02 = 'FullControl'
        $permissions03 = 'Modify'
        $ad_Group_commonShare = ''

        updateAcl $tempdtr2 $adGroup_ls_dev $permissions01
        updateAcl $tempdtr2 $wvd_admin $permissions02
        updateAcl $tempdtr2 $ad_Group_commonShare $permissions03

    }
    else{
        $permissions02 = 'FullControl'
        $permissions01 = 'Modify'
        $temp_split = $folderarray[-1]
        $ad_Group_otherfolder = '' + $temp_split + '_data'
        Write-Host ('AD group name is:')
        Write-Host $ad_Group_otherfolder
        updateAcl $tempdtr2 $wvd_admin $permissions02
        updateAcl $tempdtr2 $ad_Group_otherfolder $permissions01
    }

    }
    }

    else {

        $permissions02 = 'FullControl'
        $permissions01 = 'Modify'
        Write-Host $folderarray
        $temp_split = $folderarray[-1]
        $ad_Group = 'uapcld\azu_phx_sas_' + $temp_split + '_dev'
        Write-Host ('AD group name is:')
        Write-Host $ad_Group
        updateAcl $tempdtr2 $wvd_admin $permissions02
        updateAcl $tempdtr2 $ad_Group $permissions01

    }

    } 

    #New-Item -name 'folder111' -ItemType Directory -Path $path  
}

function updateAcl {
    param($folderpath,$adGroupname,$permissions)
    Write-Host ("I'm in updateAcl function ")
    $nhiacl = Get-Acl -Path $folderpath
    $nhiace = New-Object Security.AccessControl.FileSystemAccessRule ($adGroupname,$permissions,'None','None','Allow')
    $nhiacl.AddAccessRule($nhiace)
    Set-Acl -AclObject $nhiacl -Path $folderpath
}

foldercreation $folders
