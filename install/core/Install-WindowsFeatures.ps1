<#
.SYNOPSIS
    Install-WindowsFeatures.ps1 - Enable WSL2, Hyper-V, Virtual Machine Platform
#>
$ErrorActionPreference = "Stop"

Write-Host "  Enabling Windows Subsystem for Linux..." -ForegroundColor Gray
$wsl = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
if ($wsl.State -ne "Enabled") {
    Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -NoRestart -All | Out-Null
    Write-Host "    WSL enabled" -ForegroundColor Green
} else {
    Write-Host "    WSL already enabled" -ForegroundColor DarkGray
}

Write-Host "  Enabling Virtual Machine Platform..." -ForegroundColor Gray
$vmp = Get-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform
if ($vmp.State -ne "Enabled") {
    Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -NoRestart -All | Out-Null
    Write-Host "    Virtual Machine Platform enabled" -ForegroundColor Green
} else {
    Write-Host "    Virtual Machine Platform already enabled" -ForegroundColor DarkGray
}

Write-Host "  Enabling Hyper-V (for mirrored networking)..." -ForegroundColor Gray
try {
    $hv = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All -ErrorAction SilentlyContinue
    if ($null -eq $hv -or $hv.State -ne "Enabled") {
        Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All -NoRestart -All -ErrorAction SilentlyContinue | Out-Null
        Write-Host "    Hyper-V enabled" -ForegroundColor Green
    } else {
        Write-Host "    Hyper-V already enabled" -ForegroundColor DarkGray
    }
} catch {
    Write-Host "    Hyper-V not available (Home edition?) - continuing" -ForegroundColor Yellow
}

# Update WSL kernel
Write-Host "  Updating WSL kernel..." -ForegroundColor Gray
wsl --update 2>$null
wsl --set-default-version 2 2>$null

Write-Host "  Windows features configured" -ForegroundColor Green
exit 0
