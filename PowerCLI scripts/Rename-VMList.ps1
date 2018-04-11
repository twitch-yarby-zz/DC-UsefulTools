Param(
 [string]$vcIP,
 [string]$vcUser,
 [string]$vcPass,
 [string]$vmList
)
Import-Module -Name VMware.VimAutomation.Core -ErrorAction Stop

Set-PowerCLIConfiguration -InvalidCertificationAction ignore -confirm:$false

Write-Output "Reading in file"
$renameList = Import-CSV $vmList

Write-Output "Connecting to vCenter"
$session = Connect-ViServer -Server $vcIP -User $vcUser -Password $vcPass

if($session.IsConnected -ne $true)
{
	Write-Error "Failed to connect"
	exit 1
}

Write-Output "Begining rename"
ForEach($vmName in $renameList)
{
	$VM = Get-VM -Name $vmName.OLD_NAME
	if($VM)
	{
		Write-Output "Found VM: " $VM.Name
		$VM = Set-VM $VM -Name $vmName.NEW_NAME -Confirm:$false
		if($VM.Name -eq $vmName.NEW_NAME)
		{
			Write-Output $vmName.NEW_NAME " success" -ForegroundColor Green
		}
		else
		{
			Write-Error $vmName.OLD_NAME " failure"
		}
	}
	else
	{
		$VM = Get-VM -Name $vmName.NEW_NAME
		if ($VM)
		{
			Write-Output $vmName.NEW_NAME " already renamed" -ForegroundColor Green
		}
		else
		{
			Write-Error "Could not locate VM: " $vmName.OLD_NAME
		}
	}
}

Write-Output "Operation complete. Disconnecting"
Disconnect-ViServer $session -Confirm:$false