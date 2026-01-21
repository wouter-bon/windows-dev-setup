<#
.SYNOPSIS
    Install-WSLDistros.ps1 - Install Ubuntu and Kali Linux
#>
$ErrorActionPreference = "Stop"
$cfg = $env:DEPLOY_CONFIG | ConvertFrom-Json

function Install-Distribution {
    param([string]$DisplayName, [string]$WslName)
    
    Write-Host "  Checking $DisplayName..." -ForegroundColor Gray
    $existing = wsl -l -q 2>$null | Where-Object { $_ -match $WslName }
    
    if ($existing) {
        Write-Host "    Already installed" -ForegroundColor DarkGray
        return $true
    }
    
    Write-Host "    Installing $DisplayName (this may take several minutes)..." -ForegroundColor Yellow
    wsl --install -d $WslName --no-launch 2>$null
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "    $DisplayName installed" -ForegroundColor Green
        return $true
    } else {
        Write-Host "    $DisplayName installation failed (exit code: $LASTEXITCODE)" -ForegroundColor Yellow
        return $false
    }
}

Write-Host "  Updating WSL..." -ForegroundColor Gray
wsl --update 2>$null

# Install Ubuntu
if ($cfg.install.wsl_ubuntu) {
    Install-Distribution "Ubuntu 24.04 LTS" "Ubuntu"
}

# Install Kali Linux
if ($cfg.install.wsl_kali) {
    Install-Distribution "Kali Linux" "kali-linux"
}

# Set Ubuntu as default
Write-Host "  Setting Ubuntu as default distribution..." -ForegroundColor Gray
wsl --set-default Ubuntu 2>$null

# Display installed distributions
Write-Host "`n  Installed WSL distributions:" -ForegroundColor Cyan
wsl -l -v 2>$null

Write-Host "  WSL distributions configured" -ForegroundColor Green
exit 0
