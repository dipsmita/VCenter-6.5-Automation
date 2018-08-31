Start-Transcript-Path C:\Fakefolder\logs.txt -Append
#Add VMware snapin
Write-Host "Loading VMware Module"......
#Get-Module -Name VMware* -ListAvailable | Import-Module
Write-Host "VMware Module Loaded Successfully......"-foreground "Cyan"

Get-Content Input.Input | Foreach-Object	{
if ($_.length -gt 0) {
 $var = $_ -Split '=',2
 New-Variable -Name $var[0] -Value $var[1]
				}
Write-Host "Fetched Input File Successfully....."-foreground "Cyan"	
		
    }
	Catch {
$_ | Out-File C:\errors.txt -Append


if(!(Connect-VIServer -Server $vCenterInstance -User $vCenterUser -Password $VC_Password )) {
    write-host "Connect-VIServer -Server" + $vCenterInstance + "-User" + $vCenterUser + "-Password" + $VC_Password
    write-host "Not able to connect to the vCenter" -foreground "red"
    Exit
    }
    else {
    write-host "Connected to vCenter!" -foreground "Cyan"
    $WarningPreference = "SilentlyContinue"
    }
	}
#$vCenterPwd		= Read-Host -assecurestring Password for VCenter $vCenterInstance User $vCenterUser
#$vCenterPwd		= [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($vCenterPwd))
#$vCconnect=Connect-VIServer $vCenterInstance -User $vCenterUser -Password $vCenterPwd -WarningAction SilentlyContinue																				

	. .\function1.ps1																						
function Show-Menu
{
    param (
        [string]$Title = 'Build Automation'
    )
    #Clear-Host
    Write-Host "================ $Title ================"
    
  Write-Host "1: Press '1' for Install VCSA"
  Write-Host "2: Press '2' for Install vRSLCM"
  Write-Host "3: Press '3' for Add Hosts to VCSA"
  Write-Host "4: Press '4' for Create Distributed Switch"
 
	}
	Show-Menu -Title 'Build Automation'
 $selection = Read-Host "Please select your choice"
 switch ($selection)
 {
     '1' {
         'You chose option VCSA installation'
		 $NumOfhosts=read-host "please enter the number of hosts"
         InstallVCSA
     } '2' {
		 'You chose vRSLCM Instalation'
		 $NumOfhosts=read-host "please enter the number of hosts"
		 InstallvRSLCM	
     } '3' {
        'You chose Adding Hosts to VCSA'
        $vCenterPwd		= Read-Host -assecurestring Password
        $vCenterPwd		= [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($vCenterPwd))
        $vCconnect=Connect-VIServer $newvCenter -User $vCenterUser -Password $vCenterPwd -WarningAction SilentlyContinue																				
        Addhost
     } '4' {
        'Distributed Switch Created'
     } '5' {
        'You chose Taking snapshot'
        $vCenterPwd		= Read-Host -assecurestring Password
        $vCenterPwd		= [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($vCenterPwd))
        $vCconnect=Connect-VIServer $newvCenter -User $vCenterUser -Password $vCenterPwd -WarningAction SilentlyContinue																				
        Addhost
        
     }'q' {
         exit
     }
 }
Stop-Transcript
#. .\vRAPP.ps1
#Read-host 
#InstallvRAPP
#InstallIaaS