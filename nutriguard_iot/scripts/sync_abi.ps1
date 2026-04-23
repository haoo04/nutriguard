# 从 Windows 开发机将 NutriGuard ABI 同步到树莓派
#
# 用法:
#     .\scripts\sync_abi.ps1 -RpiHost pi@nutriguard-rpi.local
#     .\scripts\sync_abi.ps1 -RpiHost pi@192.168.1.210 -RpiPath /home/pi/nutriguard_iot
#
# 前置:
#     1. 已在开发机执行过 npx hardhat compile (生成 artifacts)
#     2. 树莓派已开启 SSH, 可用 scp 直连

param(
    [Parameter(Mandatory = $true)]
    [string]$RpiHost,

    [string]$RpiPath = "/home/pi/nutriguard_iot"
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot | Split-Path -Parent
$abiSource = Join-Path $repoRoot "Blockchain\artifacts\contracts\NutriGuard.sol\NutriGuard.json"

if (-not (Test-Path $abiSource)) {
    Write-Error "未找到 ABI 文件: $abiSource`n请先在 Blockchain 目录下运行 npx hardhat compile"
    exit 1
}

Write-Host "同步 ABI 到 $RpiHost:$RpiPath/abi/..." -ForegroundColor Cyan
scp $abiSource "${RpiHost}:${RpiPath}/abi/NutriGuard.json"

if ($LASTEXITCODE -eq 0) {
    Write-Host "ABI 同步完成 ✓" -ForegroundColor Green
} else {
    Write-Error "scp 失败, 请检查 SSH 配置"
    exit 1
}
