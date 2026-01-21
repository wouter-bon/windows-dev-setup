<#
.SYNOPSIS
    Setup-Authentication.ps1 - Guide for authenticating services
#>
$ErrorActionPreference = "Stop"
$cfg = $env:DEPLOY_CONFIG | ConvertFrom-Json

# Refresh PATH
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
$npmGlobal = Join-Path $env:USERPROFILE ".npm-global"
$localBin = Join-Path $env:USERPROFILE ".local\bin"
$env:Path = "$npmGlobal;$localBin;$env:Path"

Write-Host @"

  ╔═══════════════════════════════════════════════════════════════════╗
  ║                    SERVICE AUTHENTICATION                         ║
  ╠═══════════════════════════════════════════════════════════════════╣
  ║  The following services need one-time browser authentication:     ║
  ║                                                                   ║
  ║    1. GitHub CLI (gh)        - Repository access                  ║
  ║    2. GitHub Copilot CLI     - Terminal AI assistant              ║
  ║    3. Claude Code            - Terminal AI assistant              ║
  ║    4. VS Code Copilot        - Editor AI integration              ║
  ╚═══════════════════════════════════════════════════════════════════╝

"@ -ForegroundColor Cyan

# Check GitHub CLI
Write-Host "  GitHub CLI Status:" -ForegroundColor Magenta
$ghCmd = Get-Command gh -ErrorAction SilentlyContinue
if ($ghCmd) {
    $authStatus = gh auth status 2>&1
    if ($authStatus -match "Logged in") {
        Write-Host "    [OK] Already authenticated" -ForegroundColor Green
    } else {
        Write-Host "    [  ] Not authenticated" -ForegroundColor Yellow
        Write-Host "      Run: gh auth login" -ForegroundColor DarkGray
    }
} else {
    Write-Host "    [X] Not installed" -ForegroundColor Red
}

# Check Copilot CLI
Write-Host "`n  Copilot CLI Status:" -ForegroundColor Magenta
$copilotCmd = Get-Command copilot -ErrorAction SilentlyContinue
if ($copilotCmd) {
    Write-Host "    [OK] Installed" -ForegroundColor Green
    Write-Host "      Authenticate: run 'copilot' then type '/login'" -ForegroundColor DarkGray
} else {
    Write-Host "    [  ] Not found in PATH" -ForegroundColor Yellow
    Write-Host "      Install: npm install -g @github/copilot" -ForegroundColor DarkGray
}

# Check Claude Code
Write-Host "`n  Claude Code Status:" -ForegroundColor Magenta
$claudeCmd = Get-Command claude -ErrorAction SilentlyContinue
if ($claudeCmd) {
    Write-Host "    [OK] Installed" -ForegroundColor Green
    Write-Host "      Authenticate: run 'claude' then type '/login'" -ForegroundColor DarkGray
} else {
    Write-Host "    [  ] Not found in PATH" -ForegroundColor Yellow
    Write-Host "      Install from code.claude.ai or via winget" -ForegroundColor DarkGray
}

Write-Host @"

  ═══════════════════════════════════════════════════════════════════
  AUTHENTICATION COMMANDS (run these after deployment)
  ═══════════════════════════════════════════════════════════════════

  GitHub CLI:
    gh auth login
    (Select: GitHub.com, then HTTPS, then Login with browser)

  Copilot CLI:
    copilot
    /login
    (Browser will open for GitHub OAuth)

  Claude Code:
    claude
    /login
    (Browser will open for Anthropic OAuth)

  VS Code Copilot:
    1. Open VS Code: code .
    2. Click the Copilot icon in the status bar
    3. Sign in with your GitHub account

  ═══════════════════════════════════════════════════════════════════

"@ -ForegroundColor Gray

exit 0
