<#
.SYNOPSIS
    Install-Docker.ps1 - Install Docker Desktop with WSL2 backend
#>
$ErrorActionPreference = "Stop"
$cfg = $env:DEPLOY_CONFIG | ConvertFrom-Json

if (!$cfg.install.docker) {
    Write-Host "  Docker installation skipped (disabled in config)" -ForegroundColor Yellow
    exit 0
}

Write-Host "  Installing Docker Desktop..." -ForegroundColor Gray

# Check if already installed
$dockerCmd = Get-Command docker -ErrorAction SilentlyContinue
if ($dockerCmd) {
    Write-Host "    Docker already installed" -ForegroundColor DarkGray
    docker --version
} else {
    # Install via winget
    winget install --id Docker.DockerDesktop --silent --accept-package-agreements --accept-source-agreements 2>$null
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "    Trying direct download..." -ForegroundColor Yellow
        $installerUrl = "https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe"
        $installerPath = Join-Path $env:TEMP "DockerDesktopInstaller.exe"
        
        # Validate URL before download
        if ($installerUrl -notmatch '^https://desktop\.docker\.com/win/main/amd64/Docker%20Desktop%20Installer\.exe$') { throw "Unexpected Docker installer URL: $installerUrl" }
        Invoke-WebRequest -Uri $installerUrl -OutFile $installerPath -UseBasicParsing
        Start-Process -FilePath $installerPath -ArgumentList "install", "--quiet", "--accept-license", "--backend=wsl-2" -Wait
        Remove-Item $installerPath -Force -ErrorAction SilentlyContinue
    }
    
    Write-Host "    Docker Desktop installed" -ForegroundColor Green
}

# Configure Docker settings
Write-Host "  Configuring Docker for WSL2..." -ForegroundColor Gray

$dockerConfigDir = Join-Path $env:APPDATA "Docker"
if (!(Test-Path $dockerConfigDir)) {
    New-Item -ItemType Directory -Path $dockerConfigDir -Force | Out-Null
}

$dockerSettings = @{
    analyticsEnabled = !$cfg.security.disable_telemetry
    autoStart = $true
    displayedWelcomeMessage = $true
    licenseTermsVersion = 2
    wslEngineEnabled = $true
    integratedWslDistros = @("Ubuntu")
}

$settingsPath = Join-Path $dockerConfigDir "settings.json"
if (!(Test-Path $settingsPath)) {
    $dockerSettings | ConvertTo-Json -Depth 5 | Set-Content $settingsPath -Encoding UTF8
    Write-Host "    Docker settings configured" -ForegroundColor Green
}

# Add user to docker-users group
Write-Host "  Adding user to docker-users group..." -ForegroundColor Gray
try {
    $group = [ADSI]"WinNT://./docker-users,group"
    $user = [ADSI]"WinNT://$env:USERDOMAIN/$env:USERNAME,user"
    $group.Add($user.Path) 2>$null
    Write-Host "    User added to docker-users" -ForegroundColor Green
} catch {
    Write-Host "    docker-users group configuration skipped" -ForegroundColor DarkGray
}

Write-Host "  Docker Desktop configured" -ForegroundColor Green
Write-Host "    Note: Docker will start automatically after next login" -ForegroundColor Yellow
exit 0
