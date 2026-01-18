param(
  [Parameter(Mandatory=$true)]
  [string]$DomainName,

  [Parameter(Mandatory=$true)]
  [string]$Netbios,

  [Parameter(Mandatory=$true)]
  [string]$SafeModePass
)

$ErrorActionPreference = "Stop"

Write-Host "[DC01] Initializing data disk..."

# Find first RAW disk (the attached data disk)
$rawDisk = Get-Disk | Where-Object PartitionStyle -Eq 'RAW' | Select-Object -First 1
if (-not $rawDisk) {
  Write-Host "No RAW disk found. Assuming disk already initialized."
} else {
  Initialize-Disk -Number $rawDisk.Number -PartitionStyle GPT
  $part = New-Partition -DiskNumber $rawDisk.Number -UseMaximumSize -AssignDriveLetter
  Format-Volume -Partition $part -FileSystem NTFS -NewFileSystemLabel "ADData" -Confirm:$false
}

# Ensure drive letter F exists (best effort)
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

Write-Host "[DC01] Installing AD DS + DNS roles..."
Install-WindowsFeature AD-Domain-Services, DNS -IncludeManagementTools

Write-Host "[DC01] Promoting to new forest: $DomainName ($Netbios)"

$secPass = ConvertTo-SecureString $SafeModePass -AsPlainText -Force

Install-ADDSForest \
  -DomainName $DomainName \
  -DomainNetbiosName $Netbios \
  -DatabasePath $dbPath \
  -LogPath $logPath \
  -SysvolPath $sysvol \
  -SafeModeAdministratorPassword $secPass \
  -NoRebootOnCompletion:$false \
  -Force:$true
