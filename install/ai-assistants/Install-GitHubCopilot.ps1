<#
.SYNOPSIS
    Install-GitHubCopilot.ps1 - Install GitHub CLI and Copilot CLI
#>
$ErrorActionPreference = "Stop"
$cfg = $env:DEPLOY_CONFIG | ConvertFrom-Json

# Refresh PATH
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# Install GitHub CLI
if ($cfg.install.github_cli) {
    Write-Host "  Installing GitHub CLI..." -ForegroundColor Gray
    
    $ghCmd = Get-Command gh -ErrorAction SilentlyContinue
    if (!$ghCmd) {
        winget install --id GitHub.cli --silent --accept-package-agreements --accept-source-agreements 2>$null
        Write-Host "    GitHub CLI installed" -ForegroundColor Green
    } else {
        Write-Host "    GitHub CLI already installed" -ForegroundColor DarkGray
        gh --version 2>$null
    }
    
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
}

# Install GitHub Copilot CLI
if ($cfg.install.copilot_cli) {
    Write-Host "  Installing GitHub Copilot CLI..." -ForegroundColor Gray
    
    # Ensure npm global path
    $npmGlobal = Join-Path $env:USERPROFILE ".npm-global"
    if (!(Test-Path $npmGlobal)) { New-Item -ItemType Directory -Path $npmGlobal -Force | Out-Null }
    $env:npm_config_prefix = $npmGlobal
    $env:Path = "$npmGlobal;$env:Path"
    
    $copilotCmd = Get-Command copilot -ErrorAction SilentlyContinue
    if (!$copilotCmd) {
        Write-Host "    Installing @github/copilot via npm..." -ForegroundColor Yellow
        npm install -g @github/copilot 2>$null
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "    Copilot CLI installed" -ForegroundColor Green
        } else {
            Write-Host "    Copilot CLI installation may need retry" -ForegroundColor Yellow
        }
    } else {
        Write-Host "    Copilot CLI already installed" -ForegroundColor DarkGray
    }
}

# Configure GitHub CLI
Write-Host "  Configuring GitHub CLI..." -ForegroundColor Gray

$ghConfigDir = Join-Path $env:APPDATA "GitHub CLI"
if (!(Test-Path $ghConfigDir)) {
    New-Item -ItemType Directory -Path $ghConfigDir -Force | Out-Null
}

$ghConfig = @"
git_protocol: https
editor: code --wait
prompt: enabled
pager: less
aliases:
    co: pr checkout
    pv: pr view
    pc: pr create
    prs: pr list
"@

$ghConfigPath = Join-Path $ghConfigDir "config.yml"
if (!(Test-Path $ghConfigPath)) {
    $ghConfig | Set-Content $ghConfigPath -Encoding UTF8
    Write-Host "    GitHub CLI config created" -ForegroundColor Green
}

# Configure Copilot CLI
$copilotConfigDir = Join-Path $env:USERPROFILE ".copilot"
if (!(Test-Path $copilotConfigDir)) {
    New-Item -ItemType Directory -Path $copilotConfigDir -Force | Out-Null
}

Write-Host @"

  GitHub CLI & Copilot CLI installed:
    gh auth login     - Authenticate GitHub CLI
    copilot           - Start Copilot CLI session
    /login            - Authenticate in Copilot CLI
    /model            - Select AI model (Sonnet 4.5 default)
    /help             - Show commands

"@ -ForegroundColor Cyan

exit 0
