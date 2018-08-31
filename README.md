VMware vCenter is a management software for your vSphere environment. It manages your VMware virtual infrastructure. Current version is 6.7.
Below script is prepared in 6.5

A Software to be deployed on a Windows Server (physical or virtual)
A virtual appliance that is based on Linux (vCenter Server Appliance: VCSA)

Requirements
To deploy your VCSA 6.5 you need the following:

A running ESXi host reachable from the network
The OVA of VCSA 6.5 (you can download it from https://my.vmware.com/web/vmware/details?productId=614&downloadGroup=VC650)
At least 4GB on your host and 20GB on a datastore free in your environment

Through this script you can implement VCSA along with other components:

1.VCSA Deployment from OVA file
2.Adding Hosts to VCenter includes Cluster and Datacenter Creation
3.Create Distributed Switch

To prepare powershell for First time users:

1.Download PowerCLI (https://my.vmware.com/web/vmware/details?productId=285&downloadGroup=VSP510-PCLI-510)
2.Install-Module -Name VMware.PowerCLI
3.Set-PowerCLIConfiguration -InvalidCertificateAction Ignore 

Test the VCenter connection:
Connect-VIServer "vcenter server IP"  It will prompt for userid and Password
user:
password:
