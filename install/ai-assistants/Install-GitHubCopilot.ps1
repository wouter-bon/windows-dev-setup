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

# Verify/configure GitHub authentication with Copilot scope
Write-Host "  Verifying GitHub authentication for Copilot..." -ForegroundColor Gray

$ghCmd = Get-Command gh -ErrorAction SilentlyContinue
if ($ghCmd) {
    # Check if logged in
    $authStatus = gh auth status 2>&1
    if ($authStatus -match "Logged in") {
        # Check if copilot scope is present
        $scopes = gh auth status 2>&1 | Select-String "Token scopes"
        if ($scopes -notmatch "copilot") {
            Write-Host "    Adding copilot scope to authentication..." -ForegroundColor Yellow
            gh auth refresh -s copilot 2>$null
            if ($LASTEXITCODE -eq 0) {
                Write-Host "    Copilot scope added successfully" -ForegroundColor Green
            } else {
                Write-Host "    Run: gh auth refresh -s copilot" -ForegroundColor Yellow
            }
        } else {
            Write-Host "    GitHub auth configured with copilot scope" -ForegroundColor DarkGray
        }
    } else {
        Write-Host "    Not logged in - will need: gh auth login -s copilot" -ForegroundColor Yellow
    }
}

# Create helper function in PowerShell profile to refresh copilot auth
$profilePath = Join-Path $env:USERPROFILE "Downloads\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"
if (Test-Path $profilePath) {
    $profileContent = Get-Content $profilePath -Raw
    if ($profileContent -notlike "*copilot-refresh*") {
        $refreshFunction = @'

# Copilot CLI helper - refresh auth if token expired
function copilot-refresh {
    Write-Host "Refreshing GitHub Copilot authentication..." -ForegroundColor Cyan
    gh auth refresh -s copilot
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Authentication refreshed. Run 'copilot' to start." -ForegroundColor Green
    }
}
'@
        Add-Content -Path $profilePath -Value $refreshFunction
        Write-Host "    Added copilot-refresh helper to profile" -ForegroundColor DarkGray
    }
}

Write-Host @"

  GitHub CLI & Copilot CLI installed:
    gh auth login -s copilot  - Authenticate with Copilot scope
    gh auth refresh -s copilot - Refresh token (if expired)
    copilot-refresh           - Helper to refresh auth
    copilot                   - Start Copilot CLI session

  NOTE: If you see "Failed to get token" error, run:
        gh auth refresh -s copilot

"@ -ForegroundColor Cyan

exit 0
