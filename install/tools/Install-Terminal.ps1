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

        # Validate URL before download
        if ($fontUrl -notmatch '^https://github\.com/ryanoasis/nerd-fonts/releases/download/v[0-9.]+/.*\.zip$') { throw "Unexpected font URL: $fontUrl" }
        Invoke-WebRequest -Uri $fontUrl -OutFile $fontZip -UseBasicParsing

        # Validate download succeeded
        if (!(Test-Path $fontZip) -or (Get-Item $fontZip).Length -lt 1MB) {
            throw "Font download failed or file is too small"
        }

        Expand-Archive -Path $fontZip -DestinationPath $fontDir -Force
        
        # Install fonts (overwrite existing, handle locked files)
        $fontsFolder = "$env:LOCALAPPDATA\Microsoft\Windows\Fonts"
        if (!(Test-Path $fontsFolder)) {
            New-Item -ItemType Directory -Path $fontsFolder -Force | Out-Null
        }
        $installed = 0
        $skipped = 0
        Get-ChildItem -Path $fontDir -Filter "*.ttf" | ForEach-Object {
            $destPath = Join-Path $fontsFolder $_.Name
            $srcSize = $_.Length

            # Check if font already exists with same size (already installed)
            if ((Test-Path $destPath) -and (Get-Item $destPath).Length -eq $srcSize) {
                $skipped++
                return
            }

            # Try to copy, handle locked files gracefully
            try {
                Copy-Item -Path $_.FullName -Destination $destPath -Force -ErrorAction Stop
                $installed++
            } catch {
                # File is locked but likely already installed, skip silently
                $skipped++
                return
            }

            # Register font in user registry
            $regPath = "HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"
            $fontName = [System.IO.Path]::GetFileNameWithoutExtension($_.Name)
            Set-ItemProperty -Path $regPath -Name "$fontName (TrueType)" -Value $destPath -ErrorAction SilentlyContinue
        }

        if ($installed -gt 0) {
            Write-Host "    Nerd Fonts installed ($installed new, $skipped existing)" -ForegroundColor Green
        } else {
            Write-Host "    Nerd Fonts already installed" -ForegroundColor DarkGray
        }
        
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
