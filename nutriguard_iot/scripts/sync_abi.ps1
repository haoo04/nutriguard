# For Windows development machine to sync NutriGuard ABI to Raspberry Pi
#
# Usage:
#     .\scripts\sync_abi.ps1 -RpiHost pi@nutriguard-rpi.local
#     .\scripts\sync_abi.ps1 -RpiHost pi@192.168.1.210 -RpiPath /home/pi/nutriguard_iot
#
# Prerequisites:
#     1. Run 'npx hardhat compile' in Blockchain directory first (generates artifacts)
#     2. Raspberry Pi is accessible via SSH, and scp can be used to transfer files

param(
    [Parameter(Mandatory = $true)]
    [string]$RpiHost,

    [string]$RpiPath = "/home/pi/nutriguard_iot"
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot | Split-Path -Parent
$abiSource = Join-Path $repoRoot "Blockchain\artifacts\contracts\NutriGuard.sol\NutriGuard.json"

if (-not (Test-Path $abiSource)) {
    Write-Error "Cannot find ABI file: $abiSource"
    exit 1
}

$remotePath = "{0}:{1}/abi/NutriGuard.json" -f $RpiHost, $RpiPath

Write-Host ("Syncing ABI to {0}:{1}/abi/..." -f $RpiHost, $RpiPath)

scp "$abiSource" "$remotePath"

if ($LASTEXITCODE -eq 0) {
    Write-Host "ABI sync completed"
} else {
    Write-Error "scp failed, please check SSH configuration"
    exit 1
}