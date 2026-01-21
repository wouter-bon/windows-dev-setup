<#
.SYNOPSIS
    Install-DevTools.ps1 - Install Git, Node.js, Python, PowerShell 7, and utilities
#>
$ErrorActionPreference = "Stop"
$cfg = $env:DEPLOY_CONFIG | ConvertFrom-Json

function Install-Package {
    param([string]$Id, [string]$Name)
    
    Write-Host "    Installing $Name..." -ForegroundColor Gray
    $installed = winget list --id $Id 2>$null | Select-String $Id
    
    if ($installed) {
        Write-Host "      Already installed" -ForegroundColor DarkGray
        return
    }
    
    winget install --id $Id --silent --accept-package-agreements --accept-source-agreements 2>$null
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "      Installed" -ForegroundColor Green
    } else {
        Write-Host "      May need manual installation" -ForegroundColor Yellow
    }
}

Write-Host "  Installing Development Tools..." -ForegroundColor Cyan

# Git
if ($cfg.install.git) {
    Install-Package "Git.Git" "Git for Windows"
}

# Node.js LTS
if ($cfg.install.nodejs) {
    Install-Package "OpenJS.NodeJS.LTS" "Node.js LTS"
}

# Python
if ($cfg.install.python) {
    Install-Package "Python.Python.3.12" "Python 3.12"
}

# PowerShell 7
if ($cfg.install.powershell7) {
    Install-Package "Microsoft.PowerShell" "PowerShell 7"
}

# 7-Zip
if ($cfg.install.'7zip') {
    Install-Package "7zip.7zip" "7-Zip"
}

# jq
if ($cfg.install.jq) {
    Install-Package "jqlang.jq" "jq (JSON processor)"
}

# Refresh PATH
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# Configure npm global directory (avoid permission issues)
Write-Host "  Configuring npm..." -ForegroundColor Gray
$npmGlobal = Join-Path $env:USERPROFILE ".npm-global"
if (!(Test-Path $npmGlobal)) {
    New-Item -ItemType Directory -Path $npmGlobal -Force | Out-Null
}

$npmCmd = Get-Command npm -ErrorAction SilentlyContinue
if ($npmCmd) {
    npm config set prefix $npmGlobal 2>$null
    Write-Host "    npm global directory: $npmGlobal" -ForegroundColor DarkGray
}

Write-Host "  Development tools installed" -ForegroundColor Green
exit 0
