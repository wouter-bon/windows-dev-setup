<#
.SYNOPSIS
    Install-VSCode.ps1 - Install VS Code and extensions (GitHub Copilot, etc.)
#>
$ErrorActionPreference = "Stop"
$cfg = $env:DEPLOY_CONFIG | ConvertFrom-Json

if (!$cfg.install.vscode) {
    Write-Host "  VS Code installation skipped (disabled in config)" -ForegroundColor Yellow
    exit 0
}

# Install VS Code
Write-Host "  Installing Visual Studio Code..." -ForegroundColor Gray

$codeCmd = Get-Command code -ErrorAction SilentlyContinue
if (!$codeCmd) {
    winget install --id Microsoft.VisualStudioCode --silent --accept-package-agreements --accept-source-agreements 2>$null
    
    # Refresh PATH
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    
    Write-Host "    VS Code installed" -ForegroundColor Green
} else {
    Write-Host "    VS Code already installed" -ForegroundColor DarkGray
}

Start-Sleep -Seconds 2
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# Install extensions
Write-Host "  Installing VS Code extensions..." -ForegroundColor Gray

$extensions = @()
$extensions += $cfg.vscode.extensions.essential
$extensions += $cfg.vscode.extensions.recommended
if ($cfg.vscode.install_optional) {
    $extensions += $cfg.vscode.extensions.optional
}

$total = $extensions.Count
$current = 0

foreach ($ext in $extensions) {
    $current++
    Write-Host "    [$current/$total] $ext" -ForegroundColor Gray -NoNewline
    
    $result = & code --install-extension $ext --force 2>&1
    
    if ($LASTEXITCODE -eq 0 -or $result -match "already installed") {
        Write-Host " OK" -ForegroundColor Green
    } else {
        Write-Host " (skipped)" -ForegroundColor Yellow
    }
}

# Configure VS Code settings
Write-Host "  Configuring VS Code settings..." -ForegroundColor Gray

$vscodeConfigDir = Join-Path $env:APPDATA "Code\User"
if (!(Test-Path $vscodeConfigDir)) {
    New-Item -ItemType Directory -Path $vscodeConfigDir -Force | Out-Null
}

$vscodeSettings = @{
    # Editor
    "editor.fontSize" = 14
    "editor.fontFamily" = "'CaskaydiaCove Nerd Font', 'Cascadia Code', Consolas, monospace"
    "editor.fontLigatures" = $true
    "editor.formatOnSave" = $true
    "editor.minimap.enabled" = $false
    "editor.bracketPairColorization.enabled" = $true
    "editor.stickyScroll.enabled" = $true
    
    # Terminal
    "terminal.integrated.defaultProfile.windows" = "PowerShell"
    "terminal.integrated.fontFamily" = "'CaskaydiaCove Nerd Font'"
    "terminal.integrated.fontSize" = 13
    
    # Files
    "files.autoSave" = "afterDelay"
    "files.eol" = "`n"
    "files.trimTrailingWhitespace" = $true
    
    # Git
    "git.autofetch" = $true
    "git.confirmSync" = $false
    "git.enableSmartCommit" = $true
    
    # GitHub Copilot
    "github.copilot.enable" = @{
        "*" = $true
        "plaintext" = $true
        "markdown" = $true
    }
    "github.copilot.editor.enableAutoCompletions" = $true
    
    # Copilot Agent Mode
    "chat.agent.enabled" = $true
    "chat.agent.maxRequests" = 15
    "github.copilot.chat.agent.runTasks" = $true
    "github.copilot.chat.agent.autoFix" = $true
    
    # Telemetry
    "telemetry.telemetryLevel" = if ($cfg.security.disable_telemetry) { "error" } else { "all" }
    
    # Workbench
    "workbench.colorTheme" = "Default Dark Modern"
    "workbench.startupEditor" = "none"
}

$settingsPath = Join-Path $vscodeConfigDir "settings.json"
$vscodeSettings | ConvertTo-Json -Depth 10 | Set-Content $settingsPath -Encoding UTF8
Write-Host "    Settings configured" -ForegroundColor Green

# Keybindings
$keybindings = @(
    @{ key = "ctrl+shift+i"; command = "workbench.panel.chat.view.copilot.focus" }
    @{ key = "ctrl+i"; command = "inlineChat.start"; when = "editorTextFocus" }
)

$keybindingsPath = Join-Path $vscodeConfigDir "keybindings.json"
$keybindings | ConvertTo-Json -Depth 5 | Set-Content $keybindingsPath -Encoding UTF8
Write-Host "    Keybindings configured" -ForegroundColor Green

Write-Host "  VS Code setup complete" -ForegroundColor Green
exit 0
