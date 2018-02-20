Param(
[string]$vSphereIP,
[string]$vSphereUser,
[string]$vSpherePass,
[string]$vmName
)

Import-Module -Name VMware.VimAutomation.Core -ErrorAction Stop

Set-PowerCLIConfiguration -InvalidCertificateAction ignore -confirm:$false
$session = Connect-VIServer -Server $vSphereIP -User %vSphereUser -Password $vSpherePass

$VM = Get-VM -Name $vmName

$vmstat = "" | Select VmName, MemMax, MemAvg, MemMin, CPUMax, CPUAvg, CPUMin
$vmstat.VmName = $VM.name

$statcpu = Get-Stat -Entity ($VM)-start (get-date).AddDays(-30) -Finish (Get-Date)-MaxSamples 10000 -stat cpu.usage.average
$statmem = Get-Stat -Entity ($VM)-start (get-date).AddDays(-30) -Finish (Get-Date)-MaxSamples 10000 -stat mem.usage.average

$cpu = $statcpu | Measure-Object -Property value -Average -Maximum -Minimum
$mem = $statmem | Measure-Object -Property value -Average -Maximum -Minimum
  
$vmstat.CPUMax = $cpu.Maximum
$vmstat.CPUAvg = $cpu.Average
$vmstat.CPUMin = $cpu.Minimum
$vmstat.MemMax = $mem.Maximum
$vmstat.MemAvg = $mem.Average
$vmstat.MemMin = $mem.Minimum

$vmstat | Select-Object @{Name="CPUMax";Expression={"{0:N2}" -f $_.CPUMax}},@{Name="CPUAvg";Expression={"{0:N2}" -f $_.CPUAvg}},@{Name="CPUMin";Expression={"{0:N2}" -f $_.CPUMin}}

$vmstat | Select-Object @{Name="MemMax";Expression={"{0:N2}" -f $_.MemMax}},@{Name="MemAvg";Expression={"{0:N2}" -f $_.MemAvg}},@{Name="MemMin";Expression={"{0:N2}" -f $_.MemMin}}

$VM.Guest.Disks | Select-Object Path, @{Name="CapacityGB";Expression={"{0:N2}" -f $_.CapacityGB}}, @{Name="FreeSpaceGB";Expression={"{0:N2}" -f $_.FreeSpaceGB}}, @{Name="FreeSpacePercent";Expression={"{0:N0}" -f ($_.FreeSpaceGB / $_.CapacityGB * 100)}}

Disconnect-VIServer -server $session -confirm:$false