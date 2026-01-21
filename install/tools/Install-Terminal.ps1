<#
.SYNOPSIS
    Install-Terminal.ps1 - Install Windows Terminal and Nerd Fonts
#>
$ErrorActionPreference = "Stop"
$cfg = $env:DEPLOY_CONFIG | ConvertFrom-Json

# Install Windows Terminal
if ($cfg.install.windows_terminal) {
    Write-Host "  Installing Windows Terminal..." -ForegroundColor Gray
    
    $installed = winget list --id Microsoft.WindowsTerminal 2>$null | Select-String "Microsoft.WindowsTerminal"
    if (!$installed) {
        winget install --id Microsoft.WindowsTerminal --silent --accept-package-agreements --accept-source-agreements 2>$null
        Write-Host "    Windows Terminal installed" -ForegroundColor Green
    } else {
        Write-Host "    Windows Terminal already installed" -ForegroundColor DarkGray
    }
}

# Install Nerd Fonts (CaskaydiaCove - great for terminals)
if ($cfg.install.nerd_fonts) {
    Write-Host "  Installing Nerd Fonts (CaskaydiaCove)..." -ForegroundColor Gray
    
    try {
        $fontUrl = "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/CascadiaCode.zip"
        $fontZip = Join-Path $env:TEMP "CascadiaCode.zip"
        $fontDir = Join-Path $env:TEMP "CascadiaCode"

        Invoke-WebRequest -Uri $fontUrl -OutFile $fontZip -UseBasicParsing

        # Validate download succeeded
        if (!(Test-Path $fontZip) -or (Get-Item $fontZip).Length -lt 1MB) {
            throw "Font download failed or file is too small"
        }

        Expand-Archive -Path $fontZip -DestinationPath $fontDir -Force
        
        # Install fonts
        $fonts = (New-Object -ComObject Shell.Application).Namespace(0x14)
        Get-ChildItem -Path $fontDir -Filter "*.ttf" | ForEach-Object {
            $fonts.CopyHere($_.FullName, 0x10)
        }
        
        Write-Host "    Nerd Fonts installed" -ForegroundColor Green
        
        # Cleanup
        Remove-Item $fontZip -Force -ErrorAction SilentlyContinue
        Remove-Item $fontDir -Recurse -Force -ErrorAction SilentlyContinue
    } catch {
        Write-Host "    Nerd Fonts installation failed (non-critical): $_" -ForegroundColor Yellow
    }
}

# Configure Windows Terminal settings (basic)
Write-Host "  Configuring Windows Terminal..." -ForegroundColor Gray
$wtSettingsDir = Join-Path $env:LOCALAPPDATA "Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState"

if (Test-Path $wtSettingsDir) {
    $settingsPath = Join-Path $wtSettingsDir "settings.json"
    
    if (!(Test-Path $settingsPath)) {
        $wtSettings = @{
            '$schema' = "https://aka.ms/terminal-profiles-schema"
            defaultProfile = "{574e775e-4f2a-5b96-ac1e-a2962a402336}"  # PowerShell 7
            profiles = @{
                defaults = @{
                    font = @{
                        face = "CaskaydiaCove Nerd Font"
                        size = 12
                    }
                    colorScheme = "One Half Dark"
                    cursorShape = "bar"
                    padding = "8"
                }
            }
            schemes = @()
            actions = @(
                @{ command = "paste"; keys = "ctrl+v" }
                @{ command = "copy"; keys = "ctrl+c" }
                @{ command = @{ action = "splitPane"; split = "auto" }; keys = "alt+shift+d" }
            )
        }
        
        $wtSettings | ConvertTo-Json -Depth 10 | Set-Content $settingsPath -Encoding UTF8
        Write-Host "    Terminal settings configured" -ForegroundColor Green
    } else {
        Write-Host "    Terminal settings already exist" -ForegroundColor DarkGray
    }
} else {
    Write-Host "    Terminal not yet initialized - settings apply on first launch" -ForegroundColor Yellow
}

Write-Host "  Terminal setup complete" -ForegroundColor Green
exit 0
