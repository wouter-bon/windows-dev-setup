<#
.SYNOPSIS
    Configure-Environment.ps1 - Set environment variables and create directories
#>
$ErrorActionPreference = "Stop"
$cfg = $env:DEPLOY_CONFIG | ConvertFrom-Json

Write-Host "  Setting Environment Variables..." -ForegroundColor Gray

function Set-EnvVar {
    param([string]$Name, [string]$Value, [string]$Target = "User")
    [System.Environment]::SetEnvironmentVariable($Name, $Value, $Target)
    Write-Host "    $Name = $Value" -ForegroundColor DarkGray
}

# Development
Set-EnvVar "EDITOR" "code --wait"
Set-EnvVar "VISUAL" "code --wait"

# Docker
Set-EnvVar "DOCKER_BUILDKIT" "1"
Set-EnvVar "COMPOSE_DOCKER_CLI_BUILD" "1"

# Node.js
Set-EnvVar "NODE_OPTIONS" "--max-old-space-size=4096"
$npmGlobal = Join-Path $env:USERPROFILE ".npm-global"
Set-EnvVar "npm_config_prefix" $npmGlobal

# Python
Set-EnvVar "PYTHONDONTWRITEBYTECODE" "1"
Set-EnvVar "PYTHONUNBUFFERED" "1"

# XDG (for compatibility)
$xdgConfig = Join-Path $env:USERPROFILE ".config"
Set-EnvVar "XDG_CONFIG_HOME" $xdgConfig

# Terminal
Set-EnvVar "TERM" "xterm-256color"
Set-EnvVar "COLORTERM" "truecolor"

# Privacy / Telemetry
if ($cfg.security.disable_telemetry) {
    Set-EnvVar "DOTNET_CLI_TELEMETRY_OPTOUT" "1"
    Set-EnvVar "POWERSHELL_TELEMETRY_OPTOUT" "1"
}

# PATH additions
Write-Host "  Updating PATH..." -ForegroundColor Gray

$currentPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
if ([string]::IsNullOrWhiteSpace($currentPath)) {
    $currentPath = ""
}
$pathsToAdd = @(
    (Join-Path $env:USERPROFILE ".npm-global")
    (Join-Path $env:USERPROFILE ".local\bin")
)

# Split current path into array for exact matching
$currentPathArray = $currentPath -split ';' | Where-Object { $_ -ne '' }

foreach ($p in $pathsToAdd) {
    if ($currentPathArray -notcontains $p) {
        $currentPath = "$p;$currentPath"
        Write-Host "    Added to PATH: $p" -ForegroundColor DarkGray
    }
}
[System.Environment]::SetEnvironmentVariable("Path", $currentPath, "User")

# Create directories
Write-Host "  Creating directories..." -ForegroundColor Gray

$dirsToCreate = @(
    $npmGlobal
    (Join-Path $env:USERPROFILE ".local\bin")
    $xdgConfig
    (Join-Path $env:USERPROFILE ".copilot")
    (Join-Path $env:USERPROFILE ".claude")
)

if ($cfg.paths.create_directories) {
    $dirsToCreate += $cfg.paths.projects
    $dirsToCreate += $cfg.paths.tools
}

foreach ($dir in $dirsToCreate) {
    if (!(Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Write-Host "    Created: $dir" -ForegroundColor DarkGray
    }
}

# Refresh current session PATH
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

Write-Host "  Environment configured" -ForegroundColor Green
exit 0
