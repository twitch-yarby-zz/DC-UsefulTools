Param(
[string]$vSphereIP,
[string]$vSphereUser,
[string]$vSpherePass,
[string]$vmName
)

Import-Module -Name VMware.VimAutomation.Core -ErrorAction Stop

Set-PowerCLIConfiguration -InvalidCertificateAction ignore -confirm:$false

White-Host "Connecting to vCenter or host..."
$session = Connect-VIServer -Server $vSphereIP -User $vSphereUser -Password $vSpherePass

if($session.IsConnected -eq $true)
{
	Write-Host "Success"

	$VM = Get-VM -Name $vmName

	if($VM -ne $null)
	{
		
		Write-Host "Located VM. Retrieving data..."

		$vmstat = "" | Select VmName, MemMax, MemAvg, MemMin, CPUMax, CPUAvg, CPUMin
		$vmstat.VmName = $VM.name

		$statcpu = Get-Stat -Entity ($VM)-start (get-date).AddHours(-1) -Finish (Get-Date) -MaxSamples 10000 -stat cpu.usage.average
		$statmem = Get-Stat -Entity ($VM)-start (get-date).AddHours(-1) -Finish (Get-Date) -MaxSamples 10000 -stat mem.usage.average

		Write-Host "Processing Data..."

		$cpu = $statcpu | Measure-Object -Property value -Average -Maximum -Minimum
		$mem = $statmem | Measure-Object -Property value -Average -Maximum -Minimum
  
		$vmstat.CPUMax = $cpu.Maximum
		$vmstat.CPUAvg = $cpu.Average
		$vmstat.CPUMin = $cpu.Minimum
		$vmstat.MemMax = $mem.Maximum
		$vmstat.MemAvg = $mem.Average
		$vmstat.MemMin = $mem.Minimum

		Write-Host "Results:"
		$vmstat | Select-Object @{Name="CPU Max";Expression={"{0:N2}" -f $_.CPUMax}},@{Name="CPU Avg";Expression={"{0:N2}" -f $_.CPUAvg}},@{Name="CPU Min";Expression={"{0:N2}" -f $_.CPUMin}}

		$vmstat | Select-Object @{Name="Memory Max";Expression={"{0:N2}" -f $_.MemMax}},@{Name="Memory Avg";Expression={"{0:N2}" -f $_.MemAvg}},@{Name="Memory Min";Expression={"{0:N2}" -f $_.MemMin}}

		$VM.Guest.Disks | Select-Object Path, @{Name="Free Space (GB)";Expression={"{0:N2}" -f $_.FreeSpaceGB}}, @{Name="Total Space (GB)";Expression={"{0:N2}" -f $_.CapacityGB}} @{Name="Free Space Percent";Expression={"{0:N0}" -f ($_.FreeSpaceGB / $_.CapacityGB * 100)}}

	}
	else
	{ 
		Write-Host "Error. Unable to locate VM of name:" $vmName
	}

	Disconnect-VIServer -server $session -confirm:$false
}
else
{
	Write-Host "Failed to log in."
}

