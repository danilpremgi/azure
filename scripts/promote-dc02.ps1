param(
  [Parameter(Mandatory=$true)]
  [string]$DomainName,

  [Parameter(Mandatory=$true)]
  [string]$Netbios,

  [Parameter(Mandatory=$true)]
  [string]$DomainAdminUser,

  [Parameter(Mandatory=$true)]
  [string]$DomainAdminPass,

  [Parameter(Mandatory=$true)]
  [string]$SafeModePass
)

$ErrorActionPreference = "Stop"

Write-Host "[DC02] Initializing data disk..."

$rawDisk = Get-Disk | Where-Object PartitionStyle -Eq 'RAW' | Select-Object -First 1
if (-not $rawDisk) {
  Write-Host "No RAW disk found. Assuming disk already initialized."
} else {
  Initialize-Disk -Number $rawDisk.Number -PartitionStyle GPT
  $part = New-Partition -DiskNumber $rawDisk.Number -UseMaximumSize -AssignDriveLetter
  Format-Volume -Partition $part -FileSystem NTFS -NewFileSystemLabel "ADData" -Confirm:$false
}

$vol = Get-Volume | Where-Object FileSystemLabel -Eq "ADData" | Select-Object -First 1
if ($vol -and $vol.DriveLetter -ne 'F') {
  Set-Partition -DriveLetter $vol.DriveLetter -NewDriveLetter 'F'
}

$adRoot = "F:\AD"
$dbPath = Join-Path $adRoot "NTDS"
$logPath = Join-Path $adRoot "Logs"
$sysvol = Join-Path $adRoot "SYSVOL"

New-Item -ItemType Directory -Path $dbPath -Force | Out-Null
New-Item -ItemType Directory -Path $logPath -Force | Out-Null
New-Item -ItemType Directory -Path $sysvol -Force | Out-Null

Write-Host "[DC02] Installing AD DS + DNS roles..."
Install-WindowsFeature AD-Domain-Services, DNS -IncludeManagementTools

# Join domain first
Write-Host "[DC02] Joining domain: $DomainName"
$secPass = ConvertTo-SecureString $DomainAdminPass -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential($DomainAdminUser, $secPass)

Add-Computer -DomainName $DomainName -Credential $cred -Force -Restart

# After reboot, the script may not continue automatically.
# Custom Script Extension runs as a one-shot, so to be reliable we do the promotion in a scheduled task.
Write-Host "[DC02] Creating scheduled task for post-reboot promotion..."

$taskName = "PromoteToAdditionalDC"
$script = @"
Import-Module ADDSDeployment
`$secPass = ConvertTo-SecureString '$SafeModePass' -AsPlainText -Force
`$credPass = ConvertTo-SecureString '$DomainAdminPass' -AsPlainText -Force
`$cred = New-Object System.Management.Automation.PSCredential('$DomainAdminUser', `$credPass)
Install-ADDSDomainController -DomainName '$DomainName' -Credential `$cred -DatabasePath '$dbPath' -LogPath '$logPath' -SysvolPath '$sysvol' -SafeModeAdministratorPassword `$secPass -NoRebootOnCompletion:`$false -Force:`$true
"@

$scriptPath = "C:\Windows\Temp\promote-additional-dc.ps1"
Set-Content -Path $scriptPath -Value $script -Force -Encoding UTF8

$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File $scriptPath"
$trigger = New-ScheduledTaskTrigger -AtStartup
Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -RunLevel Highest -Force

Write-Host "[DC02] Scheduled task created. Promotion will run on next boot."
Restart-Computer -Force
