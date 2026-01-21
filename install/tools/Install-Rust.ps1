<#
.SYNOPSIS
    Install-Rust.ps1 - Install Rust toolchain via rustup
#>
$ErrorActionPreference = "Stop"
$cfg = $env:DEPLOY_CONFIG | ConvertFrom-Json

if (!$cfg.install.rust) {
    Write-Host "  Rust installation skipped (disabled in config)" -ForegroundColor Yellow
    exit 0
}

Write-Host "  Installing Rust Toolchain..." -ForegroundColor Gray

# Check if Rust is already installed
$cargoCmd = Get-Command cargo -ErrorAction SilentlyContinue
if ($cargoCmd) {
    Write-Host "    Rust already installed" -ForegroundColor DarkGray
    $version = rustc --version 2>$null
    if ($version) { Write-Host "    $version" -ForegroundColor DarkGray }
    exit 0
}

# Try winget first
Write-Host "    Installing via winget..." -ForegroundColor Gray
$wingetResult = winget install --id Rustlang.Rustup --silent --accept-package-agreements --accept-source-agreements 2>$null

if ($LASTEXITCODE -eq 0) {
    Write-Host "    Rustup installed via winget" -ForegroundColor Green
} else {
    # Fallback to direct download
    Write-Host "    Winget failed, downloading rustup-init..." -ForegroundColor Yellow
    try {
        $rustupUrl = "https://win.rustup.rs/x86_64"
        $rustupPath = Join-Path $env:TEMP "rustup-init.exe"

        Invoke-WebRequest -Uri $rustupUrl -OutFile $rustupPath -UseBasicParsing

        if (!(Test-Path $rustupPath) -or (Get-Item $rustupPath).Length -lt 1MB) {
            throw "Download failed or file too small"
        }

        # Run rustup-init with default options (no prompts)
        Write-Host "    Running rustup-init..." -ForegroundColor Gray
        Start-Process -FilePath $rustupPath -ArgumentList "-y", "--default-toolchain", "stable" -Wait -NoNewWindow

        Remove-Item $rustupPath -Force -ErrorAction SilentlyContinue
        Write-Host "    Rust installed via rustup-init" -ForegroundColor Green
    } catch {
        Write-Host "    Rust installation failed: $_" -ForegroundColor Red
        Write-Host "    Install manually from https://rustup.rs" -ForegroundColor Yellow
        exit 1
    }
}

# Add cargo bin to PATH for current session
$cargoHome = Join-Path $env:USERPROFILE ".cargo"
$cargoBin = Join-Path $cargoHome "bin"

if (Test-Path $cargoBin) {
    # Add to User PATH permanently if not already there
    $userPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
    if ($userPath -notlike "*$cargoBin*") {
        $newPath = "$cargoBin;$userPath"
        [System.Environment]::SetEnvironmentVariable("Path", $newPath, "User")
        Write-Host "    Added cargo bin to PATH" -ForegroundColor DarkGray
    }

    # Add to current session
    if ($env:Path -notlike "*$cargoBin*") {
        $env:Path = "$cargoBin;$env:Path"
    }
}

# Install common Rust tools
Write-Host "    Installing common Rust tools..." -ForegroundColor Gray

$env:Path = "$cargoBin;$env:Path"
$tools = @(
    @{ Name = "cargo-watch"; Desc = "Watch for changes and rebuild" }
    @{ Name = "cargo-edit"; Desc = "Add/remove dependencies from CLI" }
)

foreach ($tool in $tools) {
    Write-Host "      $($tool.Name)..." -ForegroundColor Gray -NoNewline
    cargo install $tool.Name --quiet 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host " OK" -ForegroundColor Green
    } else {
        Write-Host " (skipped)" -ForegroundColor Yellow
    }
}

# Verify installation
Write-Host "`n  Rust installation complete:" -ForegroundColor Green
$env:Path = "$cargoBin;$env:Path"
rustc --version 2>$null
cargo --version 2>$null

Write-Host @"

  Rust commands:
    cargo new myproject    - Create new project
    cargo build            - Build project
    cargo run              - Run project
    cargo test             - Run tests
    cargo add <crate>      - Add dependency

"@ -ForegroundColor Cyan

exit 0
