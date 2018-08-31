function InstallVCSA {
# Load OVF/OVA configuration into a variable
$ovffile = "C:\Software\vmware-vcsa.ova"
Write-Host "Loading OVA file..It will take couple of minutes..."-foreground "Cyan"
$ovfconfig = Get-OvfConfiguration $ovffile
Write-Host "OVA File Loaded Successfully...started Installing VCSA..."-foreground "Cyan"
# vSphere Cluster + VM Network configurations
$Cluster = "ICDSLABCLUSTER"
$VMName = "VCSA3"
$VMNetwork = "VM Network"
$VMHost = Get-Cluster $Cluster | Get-VMHost | Sort MemoryGB | Select-Object -first 1
$Datastore = $VMHost | Get-datastore | Sort FreeSpaceGB -Descending | Select-Object -first 1
$Network = Get-VirtualPortGroup -Name $VMNetwork -VMHost $vmhost
# Fill out the OVF/OVA configuration parameters
# vSphere Portgroup Network Mapping
$ovfconfig.NetworkMapping.Network_1.value = $Network
# tiny,small,medium,large,management-tiny,management-small,management-medium,management-large,infrastructure
$ovfconfig.DeploymentOption.value = "tiny"
# IP Protocol
$ovfconfig.IpAssignment.IpProtocol.value = "IPv4"
# IP Address Family
$ovfconfig.Common.guestinfo.cis.appliance.net.addr.family.value = "ipv4"
# IP Address Mode
$ovfconfig.Common.guestinfo.cis.appliance.net.mode.value = "static"
# IP Address 
$ovfconfig.Common.guestinfo.cis.appliance.net.addr_1.value = "10.162.6.40"
# IP PNID (same as IP Address if there's no DNS)
$ovfconfig.Common.guestinfo.cis.appliance.net.pnid.value  = "vcsa3.icdslab.net"
# IP Network Prefix (CIDR notation)
$ovfconfig.Common.guestinfo.cis.appliance.net.prefix.value = "26"
# IP Gateway
$ovfconfig.Common.guestinfo.cis.appliance.net.gateway.value = "10.162.6.1"
# DNS
$ovfconfig.Common.guestinfo.cis.appliance.net.dns.servers.value = "10.162.6.5"
# Root Password
$ovfconfig.Common.guestinfo.cis.appliance.root.passwd.value = "laptop123"
# Enable SSH
$ovfconfig.Common.guestinfo.cis.appliance.ssh.enabled.value = "True"
# SSO Domain Name
$ovfconfig.Common.guestinfo.cis.vmdir.domain_name.value = "vsphere.local"
# SSO Site Name
$ovfconfig.Common.guestinfo.cis.vmdir.site_name.value = "my-first-site"
# SSO Admin Password 
$ovfconfig.Common.guestinfo.cis.vmdir.password.value = "laptop123"
# NTP Servers
$ovfconfig.Common.guestinfo.cis.appliance.ntp.servers.value = "10.0.77.54"
# PSC Node
$ovfconfig.Common.guestinfo.cis.system.vm0.hostname.value = "10.162.6.40"
#DNS
$ovfconfig.vami.VMware_vCenter_Server_Appliance.DNS.value="10.162.6.5"
#Search Path
$ovfconfig.vami.VMware_vCenter_Server_Appliance.searchpath.value="ICDSLAB.NET"
#Domain Value
$ovfconfig.vami.VMware_vCenter_Server_Appliance.domain.value="ICDSLAB.NET"
#Gateway
$ovfconfig.vami.VMware_vCenter_Server_Appliance.gateway.value="10.162.6.1"
#Appliance IP
$ovfconfig.vami.VMware_vCenter_Server_Appliance.ip0.Value="10.162.6.40"
#Netmask Value
$ovfconfig.vami.VMware_vCenter_Server_Appliance.netmask0.Value="255.255.255.192"
# Deploy the OVF/OVA with the config parameters
Import-VApp -Source $ovffile -OvfConfiguration $ovfconfig -Name $VMName -VMHost $vmhost -Datastore $datastore -DiskStorageFormat thin
Write-Host "VCSA Deployed Successfully...."-foreground "Cyan"
							}
	

#$ErrorActionPreference = "SilentlyContinue"
function New-dvSwitch{
param($dcName, $dvSwName, $baseUplink, $nrUplink)
 
$dc = Get-View -ViewType Datacenter -Filter @{"Name"=$dcName}
$net = Get-View $dc.NetworkFolder
$spec = New-Object VMware.Vim.DVSCreateSpec
$spec.configSpec = New-Object VMware.Vim.DVSConfigSpec
$spec.configspec.name = $dvSwName
$spec.configspec.uplinkPortPolicy = New-Object VMware.Vim.DVSNameArrayUplinkPortPolicy
 
$spec.configspec.uplinkPortPolicy.UplinkPortName = (1..$nrUplink | % {$baseUplink + $_})
 
$taskMoRef = $net.CreateDVS_Task($spec)
 
$task = Get-View $taskMoRef
while("running","queued" -contains $task.Info.State){
$task.UpdateViewData("Info")
}
$task.Info.Result
}
function Get-dvSwHostCandidate{
param($container, $recursive, $dvs)
 
#$dvSwMgr.QueryCompatibleHostForExistingDvs($dc.MoRef, $true, $dvs)
}
 
function Add-dvSwHost{
param($dvSwitch, $hostMoRef, $pnic, $nrUplink)
 
$spec = New-Object VMware.Vim.DVSConfigSpec
$tgthost = New-Object VMware.Vim.DistributedVirtualSwitchHostMemberConfigSpec
$tgthost.operation = "add"
$tgthost.backing = New-Object VMware.Vim.DistributedVirtualSwitchHostMemberPnicBacking
0..($nrUplink - 1) | % {
$tgthost.Backing.PnicSpec += New-Object VMware.Vim.DistributedVirtualSwitchHostMemberPnicSpec
$tgthost.Backing.PnicSpec[$_].pnicDevice = $pnic[$_]
}
$tgthost.host = $hostMoRef
$spec.Host = $tgthost
$dvSwitch.UpdateViewData()
$spec.ConfigVersion = $dvSwitch.Config.ConfigVersion
 
$taskMoRef = $dvSwitch.ReconfigureDvs_Task($spec)
$task = Get-View $taskMoRef
while("running","queued" -contains $task.Info.State){
$task.UpdateViewData("Info")
}
}
 
$datacenterName = "LAB"
$dvSwitchName = "dvSw1"
$dvSwitchUplinkBasename = "dvUp1"
$dvSwitchUplinkNumber = 2
 
$dvSwMgr = Get-View (Get-View ServiceInstance).content.dvSwitchManager
 
$dvSwMoRef = New-dvSwitch $datacenterName $dvSwitchName $dvSwitchUplinkBasename $dvSwitchUplinkNumber
#$dvSw = Get-View $dvSwMoRef
 
$dc = Get-Datacenter $datacenterName | Get-View
$candidates = Get-dvSwHostCandidate $dc.MoRef $true $dvSwMoRef
$candidates | % {
$esx = Get-View $_
if($esx.runtime.connectionState -eq "connected"){
$pnicInUse = @()
foreach($vswitch in $esx.Config.Network.Vswitch ){
foreach($pnic in $vswitch.pnic){
$pnicInUse += $pnic
}
}
foreach($vswitch in $esx.Config.Network.ProxySwitch ){
foreach($pnic in $vswitch.pnic){
$pnicInUse += $pnic
}
}
 
$pnicFree = @()
foreach($pnic in $esx.Config.Network.Pnic){
if(!($pnicInUse -contains $pnic.Key)){
$pnicFree += $pnic.Device
}
}
if($pnicFree.Count -ge $dvSwitchUplinkNumber){
Add-dvSwHost $dvSw $esx.MoRef $pnicFree $dvSwitchUplinkNumber
}
}
}

Function OSCustomization {

#Windows server variables

$datastore		= Get-Datastore $datastoreName
$newVMportgroup		= Get-VirtualPortGroup -name $VMNetwork
$SourceVMTemplate	= Get-Template -Name $templateName
$newVMresource		= Get-ResourcePool -Name $resource
$TargetCluster		= Get-Cluster -Name $Cluster
$SourceCustomSpec	= Get-OSCustomizationSpec -Name $OSspec
$input = @(
"$ip1=$newVMName1"
"$ip2=$newVMName2"
"$ip3=$newVMName3"
"$ip4=$newVMName4"
)

#$OSspec=New-OSCustomizationSpec -Name newspec2 -OSType Windows -FullName Administrator -OrgName IBM -Domain icdslab.net -DomainUsername ashish -DomainPassword p@ssw0rd
#$SourceCustomSpec = Get-OSCustomizationSpec -Name $OSspec
Set-OSCustomizationSpec -OSCustomizationSpec $OSspec -ChangeSID $true
#Deply VM using Template
	foreach ( $line in $input )	{
			 $split	= $line -split "=";$ip=$split[0];$newVMName=$split[1];
			 $setIP	= $SourceCustomSpec | Get-OSCustomizationNicMapping | Set-OSCustomizationNicMapping -IpMode UseStaticIP -IpAddress $ip -SubnetMask $netmask -Dns $DNSServername -DefaultGateway $gateway -changesid $true
Write-Host "..............Deploying $newVMName"			 
			 New-VM -Name $newVMName -Template $SourceVMTemplate -ResourcePool $newVMresource -OSCustomizationSpec $SourceCustomSpec -VMhost $VMHost -Datastore $datastore
get-vm $newVMName 			 
Start-VM -VM $newVMName
Write-Host "VM $newVMName has been deployed and powered on" -ForegroundColor Green			 
sleep 10
Write-host "Checking... Network Adaptor $newVMName"
			 $changeVport	=	Get-VM $newVMName | Get-NetworkAdapter | Set-NetworkAdapter -NetworkName $newVMportgroup.name -Confirm:$false -Connected:$true 
Write-host "Corrected Network Adaptor $newVMName"
sleep 60
Write-host "Moving VM $newVMNameto folder $folder"
			 $a=Get-Folder $folder; $x = Move-VM -VM $newVMName -Destination $a
							}
#Reset OSCustomizationNicMapping
			 $resetIP	= Get-OSCustomizationSpec $OSspec | Get-OSCustomizationNicMapping | Set-OSCustomizationNicMapping -IpMode UseDhcp
write-host "Connecting windows servers..."
sleep 200


# Adding servers to Domain
foreach ($line in $input)	{
		$split		= $line -split "=";$server=$split[0];$dummy=$split[1];
		write-host "Adding server $dummy to Domain $domainName ..."
sleep 60
	 Try
			 {
			 $flag = "0"
Sleep 10			
			 #$domain = $domainName -replace '.com',''			 
			 Invoke-command -cn $server -credential $serCred -scriptblock {add-computer –domainname $args[0] -Credential $args[1] -restart –force} -argumentlist $domainName, $ADcred
		}
    Catch
         {
		 $flag = "1"
		 Write-Host "Unable to connect $server" -foregroundcolor Red
	}
	If 	(	$flag -eq 0	)	{
			Write-Host "The Server $dummy is added to the Domain $domainName" -ForegroundColor DarkGreen
							}
}
}