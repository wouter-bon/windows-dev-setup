<#
.SYNOPSIS
    Install-Claude.ps1 - Install Claude Desktop and Claude Code
#>
$ErrorActionPreference = "Stop"
$cfg = $env:DEPLOY_CONFIG | ConvertFrom-Json

# Refresh PATH
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# Install Claude Desktop
if ($cfg.install.claude_desktop) {
    Write-Host "  Installing Claude Desktop..." -ForegroundColor Gray
    
    $claudeDesktopPath = Join-Path $env:LOCALAPPDATA "Programs\claude-desktop"
    $installed = Test-Path $claudeDesktopPath
    
    if (!$installed) {
        # Try winget first
        $wingetResult = winget search "Claude" 2>$null | Select-String "Anthropic"
        if ($wingetResult) {
            winget install --id Anthropic.Claude --silent --accept-package-agreements --accept-source-agreements 2>$null
            Write-Host "    Claude Desktop installed" -ForegroundColor Green
        } else {
            Write-Host "    Downloading Claude Desktop installer..." -ForegroundColor Yellow
            try {
                $installerUrl = "https://storage.googleapis.com/osprey-downloads-c02f6a0d-347c-492b-a752-3e0651722e97/nest-win-x64/Claude-Setup-x64.exe"
                $installerPath = Join-Path $env:TEMP "ClaudeSetup.exe"
                
                # Validate URL before download
                if ($installerUrl -notmatch '^https://claude\.ai/installer/claude-windows\.exe$') { throw "Unexpected Claude installer URL: $installerUrl" }
                Invoke-WebRequest -Uri $installerUrl -OutFile $installerPath -UseBasicParsing
                Start-Process -FilePath $installerPath -ArgumentList "/S" -Wait
                Remove-Item $installerPath -Force -ErrorAction SilentlyContinue
                
                Write-Host "    Claude Desktop installed" -ForegroundColor Green
            } catch {
                Write-Host "    Download failed - install from claude.ai/download" -ForegroundColor Yellow
            }
        }
    } else {
        Write-Host "    Claude Desktop already installed" -ForegroundColor DarkGray
    }
}

# Install Claude Code
if ($cfg.install.claude_code) {
    Write-Host "  Installing Claude Code..." -ForegroundColor Gray
    
    $claudeCmd = Get-Command claude -ErrorAction SilentlyContinue
    
    if (!$claudeCmd) {
        # Try winget first
        winget install --id Anthropic.ClaudeCode --silent --accept-package-agreements --accept-source-agreements 2>$null
        
        if ($LASTEXITCODE -ne 0) {
            # Try npm
            Write-Host "    Trying npm installation..." -ForegroundColor Yellow
            
            $npmGlobal = Join-Path $env:USERPROFILE ".npm-global"
            $env:npm_config_prefix = $npmGlobal
            $env:Path = "$npmGlobal;$env:Path"
            
            npm install -g @anthropic-ai/claude-code 2>$null
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "    Claude Code installed via npm" -ForegroundColor Green
            } else {
                # Create local bin directory and try native method
                $localBin = Join-Path $env:USERPROFILE ".local\bin"
                if (!(Test-Path $localBin)) { New-Item -ItemType Directory -Path $localBin -Force | Out-Null }
                
                Write-Host "    Try manual install from code.claude.ai" -ForegroundColor Yellow
            }
        } else {
            Write-Host "    Claude Code installed via winget" -ForegroundColor Green
        }
    } else {
        Write-Host "    Claude Code already installed" -ForegroundColor DarkGray
        try {
            $version = claude --version 2>&1
            if ($version) { Write-Host "    Version: $version" -ForegroundColor DarkGray }
        } catch {
            # Command may not be in current session PATH
        }
    }
}

# Create Claude Code configuration
Write-Host "  Configuring Claude Code..." -ForegroundColor Gray

$claudeConfigDir = Join-Path $env:USERPROFILE ".claude"
if (!(Test-Path $claudeConfigDir)) {
    New-Item -ItemType Directory -Path $claudeConfigDir -Force | Out-Null
}

$claudeSettings = @{
    permissions = @{
        allow = @()
        deny = @()
    }
    env = @{
        API_TIMEOUT_MS = "300000"
    }
    autoUpdatesChannel = "stable"
}

$claudeSettingsPath = Join-Path $claudeConfigDir "settings.json"
if (!(Test-Path $claudeSettingsPath)) {
    $claudeSettings | ConvertTo-Json -Depth 5 | Set-Content $claudeSettingsPath -Encoding UTF8
    Write-Host "    Claude Code settings created" -ForegroundColor Green
}

Write-Host @"

  Claude tools installed:
    Claude Desktop - Launch from Start Menu
    claude         - Start Claude Code session
    /login         - Authenticate (OAuth)
    /model         - Select model
    /help          - Show commands

"@ -ForegroundColor Cyan

exit 0
